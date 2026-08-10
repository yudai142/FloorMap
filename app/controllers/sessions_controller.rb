class SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [ :check_out, :show ], if: -> { params[:id].present? }

  def check_in
    @seat = Seat.find(params[:seat_id])
    @session = current_user.sessions.build(seat: @seat, check_in_time: Time.current)
    authorize @session, :check_in?

    if @session.save
      redirect_to room_path(@seat.room), notice: "座席にチェックインしました"
    else
      redirect_to room_path(@seat.room), alert: "チェックイン失敗: #{@session.errors.full_messages.join(', ')}"
    end
  end

  def check_out
    authorize @session
    @session.check_out!

    redirect_to room_path(@session.seat.room), notice: "座席からチェックアウトしました"
  end

  def current_session
    @session = current_user.sessions.active.last
  end

  def history
    @sessions = current_user.sessions.order(check_in_time: :desc)
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end
end
