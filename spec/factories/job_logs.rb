FactoryBot.define do
  factory :job_log do
    job_type { 'CheckDailyAutoCheckoutJob' }
    status { :success }
    started_at { Time.current }
    ended_at { Time.current + 1.second }
    metadata { {} }
  end
end
