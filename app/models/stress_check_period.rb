class StressCheckPeriod < ApplicationRecord
  belongs_to :company
  has_many :stress_check_responses, dependent: :destroy
  has_many :judgments, dependent: :destroy
  has_many :results, dependent: :destroy
end
