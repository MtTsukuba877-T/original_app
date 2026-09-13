class CompanyRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :company_name, :string
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :hr_name, :string
  attribute :hr_email, :string

  # 企業情報
  validates :company_name, presence: true, length: { maximum: 100 }

  # 受検期間
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # 初代担当者情報
  validates :hr_name, presence: true, length: { maximum: 50 }
  validates :hr_email, presence: true, length: { maximum: 255 }
  validates :hr_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { hr_email.present? }
  validate :hr_email_uniqueness

  # save の結果として保存された Company を返す
  attr_reader :company

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @company = Company.create!(name: company_name)

      StressCheckPeriod.create!(
        company: @company,
        name: "#{Time.current.year}年",
        start_date: start_date,
        end_date: end_date,
        judgment_method: :simple_sum
      )

      @invited_user = User.invite!(
        {
          email: hr_email,
          name: hr_name,
          role: :company_hr,
          company: @company
        },
        nil
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    merge_model_errors(e.record)
    false
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "は受検期間開始日以降の日付を指定してください")
    end
  end

  def hr_email_uniqueness
    return if hr_email.blank?

    if User.exists?(email: hr_email)
      errors.add(:hr_email, "はすでに使用されています")
    end
  end

  # トランザクション内で起きた ActiveRecord バリデーションエラーを、
  # フォームオブジェクトのエラーに転記する
  def merge_model_errors(record)
    record.errors.each do |error|
      errors.add(:base, "#{record.class.model_name.human}の#{error.full_message}")
    end
  end
end
