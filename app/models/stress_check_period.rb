class StressCheckPeriod < ApplicationRecord
  belongs_to :company
  has_many :stress_check_responses, dependent: :destroy
  has_many :judgments, dependent: :destroy
  has_many :results, dependent: :destroy

  enum :judgment_method, { simple_sum: 0, raw_score_conversion: 1 }

  # 今日が受検期間内（開始日 ≦ 今日 ≦ 終了日）の実施回（Issue #41）。
  # 開始日・終了日が未設定（NULL）の実施回は比較が成り立たないため含まれない（＝受検できない）。
  scope :in_examination_period, -> { where("start_date <= :today AND end_date >= :today", today: Date.current) }

  validates :name, presence: true, length: { maximum: 30 },
                   uniqueness: { scope: :company_id }
  validates :judgment_method, presence: true

  validate :end_date_after_start_date
  validate :dates_both_present_or_both_absent

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "は開始日以降の日付を指定してください")
    end
  end

  def dates_both_present_or_both_absent
    if start_date.blank? != end_date.blank?
      errors.add(:base, "開始日と終了日は両方入力するか、両方未入力にしてください")
    end
  end
end
