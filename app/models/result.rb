class Result < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
end
