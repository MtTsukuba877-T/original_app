class StressCheckPeriod < ApplicationRecord
  belongs_to :company
  has_many :stress_check_responses, dependent: :destroy
  has_many :judgments, dependent: :destroy
  has_many :results, dependent: :destroy

  enum :judgment_method, { simple_sum: 0, raw_score_conversion: 1 }
end
