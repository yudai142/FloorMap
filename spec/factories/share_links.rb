FactoryBot.define do
  factory :share_link do
    room { association :room }
    sequence(:token) { |n| SecureRandom.hex(16) }
    expires_at { 7.days.from_now }

    trait :active do
      expires_at { 7.days.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
