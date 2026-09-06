FactoryBot.define do
  factory :seat do
    transient do
      seat_index { 0 }
    end

    room { association :room }
    sequence(:row_number) { |n| n % 10 }
    sequence(:column_number) { |n| (n % 8) + 1 }
    sequence(:position_x) { |n| ((n % 100) + 1) * 20 }
    sequence(:position_y) { |n| ((n / 100) + 1) * 20 }
    seat_type { :regular }

    trait :accessible do
      seat_type { :accessible }
    end

    trait :vip do
      seat_type { :vip }
    end
  end
end
