class StressCheckResponse < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :question
end
