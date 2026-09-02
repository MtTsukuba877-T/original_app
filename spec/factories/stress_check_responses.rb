FactoryBot.define do
  factory :stress_check_response do
    association :employee
    association :stress_check_period
    association :question
    raw_answer { 3 }
  end
end
