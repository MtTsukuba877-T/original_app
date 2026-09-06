class Judgment < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period
  belongs_to :section

  validates :section_score, presence: true,
                            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: [ :stress_check_period_id, :section_id ] }
end
