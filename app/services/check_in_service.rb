class CheckInService
  def initialize(seat:, user: nil, visitor: nil)
    @seat = seat
    @user = user
    @visitor = visitor
  end

  def call
    return false unless valid?

    create_session
  end

  def valid?
    @seat.present? && (@user.present? || @visitor.present?)
  end

  private

  def create_session
    Session.create(
      seat: @seat,
      user: @user,
      visitor: @visitor,
      check_in_time: Time.current,
      status: :active
    )
  end
end
