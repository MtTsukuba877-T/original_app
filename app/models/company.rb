class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
  has_many :stress_check_periods, dependent: :restrict_with_error
  has_many :line_friends, dependent: :restrict_with_error
end
