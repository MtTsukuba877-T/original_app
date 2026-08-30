class AnswerOption < ApplicationRecord
  belongs_to :section

  validates :answer_number, presence: true,
                            uniqueness: { scope: :section_id },
                            numericality: { only_integer: true, in: 1..4 }
  validates :text, presence: true, length: { maximum: 50 }
end
