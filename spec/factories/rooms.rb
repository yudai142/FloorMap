FactoryBot.define do
  factory :room do
    sequence(:name) { |n| "Meeting Room #{n}" }
    description { "A test room" }
    user { association :user, :manager }
  end
end
