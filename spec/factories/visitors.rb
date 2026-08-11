FactoryBot.define do
  factory :visitor do
    session_id { SecureRandom.hex(16) }
    nickname { Faker::Name.first_name }
  end
end
