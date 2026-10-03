class Section < ApplicationRecord
  has_many :questions, dependent: :restrict_with_error
  has_many :answer_options, dependent: :restrict_with_error
  has_many :judgments, dependent: :destroy

  validates :code, presence: true, uniqueness: true, length: { maximum: 10 }
  validates :name, presence: true, length: { maximum: 50 }
  validates :intro_text, presence: true
  validates :display_order, presence: true, uniqueness: true,
             numericality: { only_integer: true, greater_than: 0 }

  # 表示順で1つ前のセクション（最初のセクションなら nil）（Issue #41）
  def previous_section
    Section.where("display_order < ?", display_order).order(:display_order).last
  end

  # 表示順で1つ後のセクション（最後のセクションなら nil）（Issue #41）
  def next_section
    Section.where("display_order > ?", display_order).order(:display_order).first
  end
end
