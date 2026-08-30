FactoryBot.define do
  factory :answer_option do
    association :section
    sequence(:answer_number) { |n| ((n - 1) % 4) + 1 }
    text { "そうだ" }
  end
end
