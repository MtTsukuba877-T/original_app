class Company < ApplicationRecord
  # お試し受検（デモ）用の企業の名前（Issue #160）。seeds と、お試し受検の入口で使う。
  TRIAL_COMPANY_NAME = "デモンストレーション企業".freeze

  has_many :users, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
  has_many :stress_check_periods, dependent: :restrict_with_error
  has_many :line_friends, dependent: :restrict_with_error

  # 企業担当者(role: company_hr)だけを取得する scope
  has_many :company_hrs, -> { where(role: :company_hr) }, class_name: "User"

  validates :name, presence: true, length: { maximum: 100 }
end
