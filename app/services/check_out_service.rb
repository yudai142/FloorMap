class CheckOutService
  def initialize(session:)
    @session = session
  end

  def call
    return false unless valid?

    update_session_status
  end

  def valid?
    @session.present? && @session.active?
  end

  private

  def update_session_status
    @session.update(
      check_out_time: Time.current,
      status: :completed
    )
  end
end
