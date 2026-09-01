FactoryBot.define do
  factory :line_friend do
    association :company
    sequence(:line_user_id) { |n| "U#{n.to_s.rjust(32, '0')}" }
    # employee は初期状態で nil (紐付け前)
    employee { nil }
    # トークン関連は初期状態で全て nil
    initial_reg_token { nil }
    token_generated_at { nil }
    token_send_count { 0 }
    token_expires_at { nil }

    trait :with_token do
      sequence(:initial_reg_token) { |n| "TOKEN#{n.to_s.rjust(40, '0')}" }
      token_generated_at { Time.current }
      token_expires_at { Time.current + 7.days }
      token_send_count { 1 }
    end

    trait :linked_to_employee do
      association :employee
    end
  end
end
