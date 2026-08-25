class Employee < ApplicationRecord
  has_secure_password
  belongs_to :company
  has_one :line_friend, dependent: :destroy
  has_many :stress_check_responses, dependent: :destroy
  has_many :judgments, dependent: :destroy
  has_many :results, dependent: :destroy

  enum :sex, { male: 1, female: 2 }
end
