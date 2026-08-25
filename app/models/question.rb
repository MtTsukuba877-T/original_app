class Question < ApplicationRecord
  belongs_to :section
  has_many :stress_check_responses, dependent: :destroy

  enum :question_type, { standard_57: 57, extended_80: 80 }
end
