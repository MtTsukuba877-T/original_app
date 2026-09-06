FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "ユーザー#{n}" }

    # デフォルトは system_admin (company_id: nil)
    role { :system_admin }
    company { nil }

    trait :company_hr do
      role { :company_hr }
      association :company
    end
  end
end
