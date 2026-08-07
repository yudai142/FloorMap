FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_2fa_enabled do
      otp_required_for_login { true }
      otp_secret_key { ROTP::Base32.random_base32 }
    end
  end
end
