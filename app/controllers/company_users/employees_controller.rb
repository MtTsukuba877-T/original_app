class CompanyUsers::EmployeesController < ApplicationController
  layout "admin"
  before_action :authenticate_user!

  # CSV アップロード画面表示（GET /company_users/employees/csv_upload）
  def csv_upload
    # form_with model: で使うための空のフォームオブジェクトを準備
    @form = EmployeeCsvImportForm.new
  end

  # CSV アップロード実行（POST /company_users/employees/csv_import）
  def csv_import
    @form = EmployeeCsvImportForm.new(
      employee_csv_import_form_params.merge(company: current_user.company)
    )

    if @form.save
      # 全件成功: 同一画面に成功メッセージを表示
      flash.now[:notice] = "#{@form.imported_count}件の受検者を登録しました。"
      render :csv_upload, status: :ok
    else
      # 失敗（バリデーションエラー or 一部行のエラー）: 同一画面にエラー表示
      # @form.error_rows と @form.errors を View で表示
      render :csv_upload, status: :unprocessable_entity
    end
  end

  # テンプレート CSV ダウンロード（GET /company_users/employees/csv_template）
  def csv_template
    csv_data = CSV.generate(encoding: "UTF-8") do |csv|
      # ヘッダー行
      csv << EmployeeCsvImportForm::EXPECTED_HEADERS

      # サンプルデータ行(3件、日付3形式のバリエーションを含む)
      # 氏名に「サンプル」を含め、視覚的にサンプルデータであることを示す。
      # 万一削除し忘れてアップロードされた場合も、実在の従業員として登録される
      # リスクを低減する意図。
      csv << [ "E001", "サンプル太郎", "1980-03-15", "男", "営業部", "taro.sample@example.com" ]
      csv << [ "E002", "サンプル花子", "1985/09/21", "女", "", "" ]
      csv << [ "E003", "サンプル次郎", "19750408", "男", "総務部", "jiro.sample@example.com" ]
    end

    # BOM (Byte Order Mark) を先頭に付与。
    # 目的: Excel でダブルクリックした際に文字化けを防ぐ。
    # Excel は BOM の有無で文字コードを判定し、BOM が無い UTF-8 CSV を
    # Shift_JIS だと誤判定してしまう(日本語環境の Excel の仕様上の癖)。
    bom = "\uFEFF"
    send_data bom + csv_data,
              filename: "employee_template.csv",
              type: "text/csv; charset=utf-8"
  end

  private

  # Strong Parameters: csv_file のみ許可（company は params から受け取らずログイン情報から取得）
  def employee_csv_import_form_params
    params.require(:employee_csv_import_form).permit(:csv_file)
  end
end
