FactoryBot.define do
  factory :room_permission do
    user { association :user }
    room { association :room }
    permission_type { :view }
  end
end
