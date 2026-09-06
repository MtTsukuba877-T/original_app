class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :validatable

  belongs_to :company, optional: true

  enum :role, { system_admin: 0, company_hr: 1 }

  validates :name, presence: true, length: { maximum: 50 }
  validates :role, presence: true
  validates :company, presence: true, if: :company_hr?
  validates :company, absence: true, if: :system_admin?
end
