class Result < ApplicationRecord
  belongs_to :employee
  belongs_to :stress_check_period

  enum :stress_level, { high_stress: 0, low_to_moderate_stress: 1 }
end
