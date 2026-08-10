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
end
