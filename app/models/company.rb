class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
end
