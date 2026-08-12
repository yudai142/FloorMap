FactoryBot.define do
  factory :session do
    association :seat
    association :user
    check_in_time { Time.current - 2.hours }
    check_out_time { nil }
    status { "active" }

    trait :checked_out do
      check_out_time { Time.current }
      status { "checked_out" }
    end

    trait :timed_out do
      check_out_time { Time.current }
      status { "timed_out" }
    end

    trait :with_visitor do
      user { nil }
      association :visitor
    end
  end
end
