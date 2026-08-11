class CheckDailyAutoCheckoutJob < ApplicationJob
  queue_as :default

  def perform
    start_time = Time.current
    checked_out_count = 0

    begin
      checked_out_count = auto_checkout_expired_sessions

      JobLog.create!(
        job_type: self.class.name,
        status: :success,
        started_at: start_time,
        ended_at: Time.current,
        metadata: {
          checked_out_count: checked_out_count,
          expired_count: checked_out_count
        }
      )
    rescue StandardError => e
      JobLog.create!(
        job_type: self.class.name,
        status: :error,
        started_at: start_time,
        ended_at: Time.current,
        metadata: {
          error_message: e.message,
          error_class: e.class.name
        }
      )
      raise e
    end
  end

  private

  def auto_checkout_expired_sessions
    timeout_hours = 24
    threshold_time = Time.current - timeout_hours.hours

    expired_sessions = Session.where(status: :active)
                              .where('check_in_time < ?', threshold_time)

    count = 0
    expired_sessions.each do |session|
      session.update(status: :expired, check_out_time: Time.current)
      count += 1
    end

    count
  end
end
