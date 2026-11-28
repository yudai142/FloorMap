FactoryBot.define do
  factory :floor_plan_template do
    association :user
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    floor_plan_data { [] }
    is_public { false }
    usage_count { 0 }
  end
end
