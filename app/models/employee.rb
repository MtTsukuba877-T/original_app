class Employee < ApplicationRecord
  has_secure_password

  belongs_to :company
  has_one :line_friend, dependent: :destroy
  has_many :stress_check_responses, dependent: :destroy
  has_many :judgments, dependent: :destroy
  has_many :results, dependent: :destroy

  enum :sex, { male: 1, female: 2 }

  validates :examinee_number, presence: true, length: { maximum: 15 },
                              uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 50 }
  validates :date_of_birth, presence: true
  validates :sex, presence: true
  validates :department, length: { maximum: 100 }
  validates :email, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # パスワードバリデーションは「本人がパスワード変更した後のみ」適用する。
  # 理由:
  # - 初期パスワードは CSV 名簿登録時に生年月日（数字のみ8桁）を自動セットするため、
  #   「英数字混在」ルールとは両立しない。
  # - password_changed_at が nil の間は「初回ログイン扱い」(マイグレーションのコメント参照)。
  #   初回ログイン時に強制パスワード変更フロー（Phase 5 Issue #40）でこの制約を課す。
  # - 変更後の再変更時（password_changed_at が present）にもバリデーションが適用される。
  #
  # 【本リリース版での変更予定】
  # - 個別登録機能（Issue #26）追加時、登録経路ごとにフォームオブジェクトを分けて
  #   初期パスワード生成ロジックを実装する予定。
  # - 初期パスワードの要件変更（生年月日8桁以外への変更）を検討中。
  #   変更時は各フォームオブジェクトの生成ロジックを修正し、
  #   必要に応じてこの if 条件式も再検討する。
  validates :password, length: { minimum: 8 },
                       format: {
                         with: /\A(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]+\z/,
                         message: "は半角英数字混在で入力してください"
                       },
                       if: -> { password_changed_at.present? && password.present? }

  # パスワード変更画面（E-4）で保存するときだけ、パスワードの入力を必須にする（Issue #40）。
  # has_secure_password は空欄を「変更なし」として無視するため、このチェックがないと、
  # 初期パスワードのまま password_changed_at だけが更新されてしまう。
  validates :password, presence: true, on: :password_change

  # 初期パスワードのまま（まだ変更していない）かどうか
  def password_change_required?
    password_changed_at.nil?
  end

  # この実施回の回答が保存済み（＝受検済み）かどうか（Issue #42）。
  # 回答は「全部か0件か」で保存するため、1件でもあれば受検済みとみなす。
  # 全問そろっているかの確認は、判定処理（Issue #44）で行う。
  def responded_to?(stress_check_period)
    stress_check_responses.exists?(stress_check_period: stress_check_period)
  end

  # 「回答を送信する」を押したときの処理（Issue #44）。
  # 預かっていた回答の保存と、セクション別スコアの計算・保存を、1つのトランザクションで行う。
  # どこかで例外が発生すると、回答もスコアもすべて取り消される（全部か0件か）。
  # Issue #45 で、高ストレスの判定をここに加える。
  #
  # answers の形は StressCheckResponse.save_answers! と同じ。
  def submit_answers!(stress_check_period:, answers:)
    transaction do
      StressCheckResponse.save_answers!(employee: self, stress_check_period: stress_check_period, answers: answers)
      Judgment.create_section_scores!(employee: self, stress_check_period: stress_check_period)
    end
  end
end
