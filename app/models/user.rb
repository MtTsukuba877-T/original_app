class User < ApplicationRecord
  # Devise モジュール構成:
  #   採用: :database_authenticatable(メール+パスワード認証)
  #        :recoverable(パスワードリセット)
  #        :validatable(メール・パスワードのバリデーション)
  #        :invitable(招待メール、devise_invitable gem)
  #   除外: :registerable(新規登録は招待経由のみのため不要)
  #        :confirmable(メール確認は MVP スコープ外)
  #        :lockable(アカウントロックは MVP スコープ外)
  #        :rememberable(セキュリティ優先で除外)
  #        :timeoutable, :trackable, :omniauthable(未使用)
  devise :invitable, :database_authenticatable,
         :recoverable, :validatable

  belongs_to :company, optional: true

  enum :role, { system_admin: 0, company_hr: 1 }

  validates :name, presence: true, length: { maximum: 50 }
  validates :role, presence: true
  validates :company, presence: true, if: :company_hr?
  validates :company, absence: true, if: :system_admin?
end
