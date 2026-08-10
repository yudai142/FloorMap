FactoryBot.define do
  factory :notification do
    user { association :user }
    room { association :room, user: build(:user, :manager) }
    notification_type { :check_in }
    title { "テストユーザーがチェックインしました。" }
    body { "チェックインイベントが発生しました。" }
    read_at { nil }
  end
end
