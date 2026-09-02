FactoryBot.define do
  factory :result do
    association :employee
    association :stress_check_period
    stress_level { :low_to_moderate_stress }
  end
end
