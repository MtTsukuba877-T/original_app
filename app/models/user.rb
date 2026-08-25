class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :validatable

  enum :role, { system_admin: 0, company_hr: 1 }

  belongs_to :company, optional: true
end
