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
  validates :password, length: { minimum: 8 },
                       format: {
                         with: /\A(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]+\z/,
                         message: "は半角英数字混在で入力してください"
                       },
                       if: -> { new_record? || password.present? }
end
