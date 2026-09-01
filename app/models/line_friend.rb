class LineFriend < ApplicationRecord
  belongs_to :company
  belongs_to :employee, optional: true

  validates :line_user_id, presence: true, length: { maximum: 50 },
                           uniqueness: { scope: :company_id }
  validates :initial_reg_token, uniqueness: true, allow_nil: true,
                                length: { maximum: 50 }
  validates :token_send_count, numericality: { greater_than_or_equal_to: 0 }

  # トークン設定時、発行日時と有効期限も必須
  validates :token_generated_at, presence: true, if: :initial_reg_token?
  validates :token_expires_at, presence: true, if: :initial_reg_token?

  # トークン有効期限は発行日時より後でなければならない
  validate :token_expires_at_after_generated_at

  private

  def initial_reg_token?
    initial_reg_token.present?
  end

  def token_expires_at_after_generated_at
    return if token_generated_at.blank? || token_expires_at.blank?

    if token_expires_at <= token_generated_at
      errors.add(:token_expires_at, "はトークン発行日時より後の日時である必要があります")
    end
  end
end
