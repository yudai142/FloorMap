FactoryBot.define do
  factory :session do
    user
    seat
    check_in_time { Time.current }
    check_out_time { nil }
    status { :active }

    trait :checked_out do
      check_out_time { Time.current + 1.hour }
      status { :completed }
    end

    trait :expired do
      check_in_time { 24.hours.ago }
      check_out_time { nil }
      status { :expired }
    end
  end
end
