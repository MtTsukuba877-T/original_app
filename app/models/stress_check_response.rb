class StressCheckResponse < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :question

  validates :raw_answer, presence: true,
                         numericality: { only_integer: true, in: 1..4 }
  validates :employee_id, uniqueness: { scope: [ :stress_check_period_id, :question_id ] }
end
