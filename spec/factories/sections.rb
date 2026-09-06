FactoryBot.define do
  factory :section do
    sequence(:code) { |n| "code_#{n}" }
    name { "セクションA" }
    intro_text { "このセクションでは、あなたのお仕事についてお伺いします。" }
    sequence(:display_order) { |n| n }
  end
end
