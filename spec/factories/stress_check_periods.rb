FactoryBot.define do
  factory :stress_check_period do
    association :company
    sequence(:name) { |n| "2026年度 第#{n}回" }
    start_date { Date.new(2026, 4, 1) }
    end_date { Date.new(2026, 4, 30) }
    judgment_method { :simple_sum }
  end
end
