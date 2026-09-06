FactoryBot.define do
  factory :question do
    question_type { :standard_57 }
    association :section
    sequence(:question_number) { |n| n }
    content { "最近、次のように感じることがどれくらいありましたか。" }
    reversed { false }
  end
end
