FactoryBot.define do
  factory :employee do
    association :company
    sequence(:examinee_number) { |n| "EMP#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "従業員#{n}" }
    date_of_birth { Date.new(1990, 1, 1) }
    sex { :male }
    password { "password123" }
  end
end
