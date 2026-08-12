class SessionsController < ApplicationController
  before_action :authenticate_user!, except: [ :check_in_form, :check_in ]
  before_action :authorize_session, only: [ :check_out ]

  def check_in_form
    @rooms = current_user ? current_user.rooms : []
    @seats = if params[:room_id].present?
      Seat.where(room_id: params[:room_id]).order(:row_number, :column_number)
    else
      Seat.none
    end
    @current_session = current_user&.sessions&.active&.last
  end

  def check_in
    seat = Seat.find_by(id: params[:seat_id])
    return render json: { error: "座席が見つかりません" }, status: :not_found unless seat

    session = Session.create(
      user_id: current_user&.id,
      seat_id: seat.id,
      check_in_time: Time.current,
      status: "active"
    )

    if session.persisted?
      broadcast_check_in(session, seat.room)
      redirect_to sessions_path, notice: "チェックインしました"
    else
      render :check_in_form, alert: "チェックインに失敗しました"
    end
  end

  def check_out
    @session = Session.find_by(id: params[:session_id])
    return render json: { error: "セッションが見つかりません" }, status: :not_found unless @session

    authorize_session

    if @session.update(check_out_time: Time.current, status: "checked_out")
      broadcast_check_out(@session, @session.room)
      redirect_to sessions_path, notice: "チェックアウトしました"
    else
      render json: { error: "チェックアウトに失敗しました" }, status: :unprocessable_entity
    end
  end

  def history
    @sessions = if current_user
      current_user.sessions.completed.recent.page(params[:page])
    else
      Session.none
    end
  end

  private

  def authorize_session
    session = Session.find_by(id: params[:session_id])
    unless session && (session.user_id == current_user.id || current_user.admin?)
      render json: { error: "権限がありません" }, status: :forbidden
    end
  end

  def broadcast_check_in(session, room)
    ActionCable.server.broadcast(
      "room_#{room.id}",
      { type: "check_in", session_id: session.id, seat_id: session.seat_id, user_id: session.user_id }
    )
  end

  def broadcast_check_out(session, room)
    ActionCable.server.broadcast(
      "room_#{room.id}",
      { type: "check_out", session_id: session.id, seat_id: session.seat_id, user_id: session.user_id }
    )
  end
end
