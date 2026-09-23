require "csv"

class EmployeeCsvImportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # 外部から受け取る属性
  attribute :csv_file            # アップロードされた CSV ファイル (ActionDispatch::Http::UploadedFile)
  attribute :company             # 現在ログイン中の企業（Company オブジェクト）

  # save の結果として外部から参照される属性
  attr_reader :imported_count    # 登録成功件数（Integer）
  attr_reader :error_rows        # エラー行の配列 [{row_number: Int, messages: [String]}, ...]

  # CSV の想定ヘッダー（Issue #23 の設計判断で確定した6カラム、順序固定）
  EXPECTED_HEADERS = [ "受検者番号", "氏名", "生年月日", "性別", "所属部署", "メールアドレス" ].freeze

  # 外部入力属性のバリデーション
  validates :csv_file, presence: { message: "を選択してください" }
  validates :company, presence: true

  # フォームオブジェクト全体を保存する
  def save
    @imported_count = 0
    @error_rows = []

    return false unless valid?

    # CSV をパースして行の配列に変換（ヘッダー検証もこの中で実施）
    rows = parse_csv
    return false if rows.nil?  # パース失敗時は errors に追加済み

    # 各行を Employee インスタンスに変換（row_number は CSV 上の行番号、ヘッダー行を1とする）
    employees_with_row_numbers = rows.map.with_index(2) do |row, row_number|
      [ build_employee_from_row(row, row_number), row_number, row ]
    end

    # トランザクション: 1件でもエラーがあれば全件ロールバック
    ActiveRecord::Base.transaction do
      employees_with_row_numbers.each do |employee, row_number, row|
        # 列数不一致のチェック（build_employee_from_row では空の Employee を返しているため、
        # ここでエラー行として記録する）
        if row.length != EXPECTED_HEADERS.length
          @error_rows << {
            row_number: row_number,
            messages: [ "列数が想定と異なります（想定: #{EXPECTED_HEADERS.length}列、実際: #{row.length}列）" ]
          }
          next
        end

        if employee.save
          @imported_count += 1
        else
          # パスワードエラーは非表示（CSV に password 欄が無いため、企業担当者を混乱させないため）。
          # パスワードは date_of_birth から自動生成されるため、日付エラーが表示されれば
          # 企業担当者は生年月日欄を修正するだけで自動的にパスワード問題も解消される。
          messages = employee.errors.reject { |error| error.attribute == :password }.map(&:full_message)
          @error_rows << {
            row_number: row_number,
            messages: messages
          }
        end
      end

      # 1件でもエラーがあれば全件ロールバック
      if @error_rows.any?
        @imported_count = 0
        raise ActiveRecord::Rollback
      end
    end

    @error_rows.empty?
  end

  private

  # CSV ファイルをパースして、ヘッダーを除いたデータ行の配列を返す。
  # 失敗時は errors に追加して nil を返す。
  def parse_csv
    # ファイル内容を読み込み、文字コードを UTF-8 に統一
    content = read_and_normalize_encoding
    return nil if content.nil?

    # CSV パース
    rows = CSV.parse(content)
    if rows.empty?
      errors.add(:csv_file, "は空のファイルです")
      return nil
    end

    # ヘッダー行の検証
    header = rows.first
    unless header == EXPECTED_HEADERS
      errors.add(:csv_file, "のヘッダー行が想定と異なります（想定: #{EXPECTED_HEADERS.join(', ')}）")
      return nil
    end

    # ヘッダーを除いたデータ行を返す
    rows[1..]
  rescue CSV::MalformedCSVError => e
    errors.add(:csv_file, "の形式が不正です（#{e.message}）")
    nil
  end

  # ファイル内容を読み込み、文字コードを判定して UTF-8 に統一する。
  # 失敗時は errors に追加して nil を返す。
  def read_and_normalize_encoding
    binary = csv_file.read

    # UTF-8 として解釈できるか試みる
    utf8_attempt = binary.dup.force_encoding("UTF-8")
    if utf8_attempt.valid_encoding?
      # BOM (Byte Order Mark) が先頭にある場合は除去する。
      # Excel で保存された UTF-8 CSV や、当システムのテンプレート CSV には
      # BOM が含まれる。BOM が残っていると、ヘッダー行の先頭カラムに
      # BOM 文字がくっついた状態になり、ヘッダー検証が失敗する。
      return utf8_attempt.delete_prefix("\uFEFF")
    end

    # UTF-8 が不正なら Shift_JIS として解釈し、UTF-8 に変換
    binary.force_encoding("Shift_JIS")
    binary.encode("UTF-8")
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    errors.add(:csv_file, "の文字コードが不正です（UTF-8 または Shift_JIS で保存してください）")
    nil
  end

  # CSV の 1 行から Employee インスタンスを組み立てて返す。
  # 属性変換に失敗した場合も、失敗内容は Employee の errors に追加されず、
  # このメソッド自体は Employee オブジェクトを返す（バリデーションは呼び出し元で実施）。
  def build_employee_from_row(row, row_number)
    # 列数チェック
    if row.length != EXPECTED_HEADERS.length
      # 列数が異なる場合は、後続のバリデーションで確実に失敗させるため、
      # 空の Employee を返す（row_number は呼び出し元でエラー行として扱う）
      return Employee.new(company: company)
    end

    examinee_number, name, date_of_birth_str, sex_str, department, email = row.map { |v| v&.strip }

    employee = Employee.new(
      company: company,
      examinee_number: examinee_number,
      name: name,
      department: department.presence,
      email: email.presence
    )

    # 日付変換（失敗時は nil のまま → 後続の presence バリデーションで捕捉）
    employee.date_of_birth = parse_date(date_of_birth_str)

    # 性別変換（未対応の値は nil のまま → 後続の presence バリデーションで捕捉）
    employee.sex = parse_sex(sex_str)

    # 初期パスワード = 生年月日 YYYYMMDD（生年月日が nil なら nil のまま）
    employee.password = employee.date_of_birth&.strftime("%Y%m%d")

    # password_changed_at は明示的に nil のまま（初回ログイン扱い）
    employee
  end

  # 日付文字列を Date オブジェクトに変換する。3形式に対応:
  # - "YYYY-MM-DD"
  # - "YYYY/MM/DD"
  # - "YYYYMMDD"
  # 変換不能な場合は nil を返す。
  def parse_date(str)
    return nil if str.blank?

    case str
    when /\A\d{4}-\d{1,2}-\d{1,2}\z/
      Date.strptime(str, "%Y-%m-%d") rescue nil
    when /\A\d{4}\/\d{1,2}\/\d{1,2}\z/
      Date.strptime(str, "%Y/%m/%d") rescue nil
    when /\A\d{8}\z/
      Date.strptime(str, "%Y%m%d") rescue nil
    end
  end

  # 性別文字列を enum のキーに変換する。"男" → :male, "女" → :female。
  # 未対応の値は nil を返す。
  def parse_sex(str)
    case str
    when "男" then :male
    when "女" then :female
    end
  end
end
