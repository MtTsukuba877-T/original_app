FactoryBot.define do
  factory :judgment do
    association :employee
    association :stress_check_period
    association :section
    section_score { 10 }
  end
end
