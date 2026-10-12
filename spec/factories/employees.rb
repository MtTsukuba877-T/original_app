FactoryBot.define do
  factory :employee do
    association :company
    sequence(:examinee_number) { |n| "EMP#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "従業員#{n}" }
    date_of_birth { Date.new(1990, 1, 1) }
    sex { :male }
    password { "password123" }

    # パスワード変更済みの受検者（Issue #40）
    # 既定（password_changed_at: nil）は、CSV で登録された直後の初期パスワードの状態。
    trait :password_changed do
      password_changed_at { Time.current }
    end
  end
end
