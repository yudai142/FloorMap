FactoryBot.define do
  factory :seat do
    room { association :room }
    sequence(:row_number) { |n| n % 10 }
    sequence(:column_number) { |n| (n % 8) + 1 }
    position_x { rand(50..1950) }
    position_y { rand(50..1950) }
    seat_type { :regular }

    trait :accessible do
      seat_type { :accessible }
    end

    trait :vip do
      seat_type { :vip }
    end
  end
end
