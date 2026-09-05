class Question < ApplicationRecord
  belongs_to :section
  has_many :stress_check_responses, dependent: :destroy

  enum :question_type, { standard_57: 57, extended_80: 80 }

  validates :question_type, presence: true
  validates :question_number, presence: true,
                              uniqueness: { scope: [ :question_type, :section_id ] },
                              numericality: { only_integer: true, greater_than: 0 }
  validates :content, presence: true, length: { maximum: 255 }
  validates :reversed, inclusion: { in: [ true, false ] }
  validates :group_text, absence: true, unless: :section_c?
  validates :group_text, length: { maximum: 100 }, allow_nil: true

  private

  def section_c?
    section&.code == "c"
  end
end
