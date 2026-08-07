FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :user }

    trait :with_2fa_enabled do
      otp_required_for_login { true }
      otp_secret_key { ROTP::Base32.random_base32 }
    end

    trait :manager do
      role { :manager }
    end

    trait :admin do
      role { :admin }
    end
  end

  factory :room do
    sequence(:name) { |n| "Meeting Room #{n}" }
    description { "A test room" }
    user { association :user, :manager }
  end

  factory :room_permission do
    user { association :user }
    room { association :room }
    permission_type { :view }
  end
end
