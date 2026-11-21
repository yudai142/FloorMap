FactoryBot.define do
  factory :floor_plan_template_seat do
    association :floor_plan_template
    sequence(:position_x) { |n| 40.0 * n }
    sequence(:position_y) { |n| 40.0 * n }
    seat_type { "regular" }
  end
end
