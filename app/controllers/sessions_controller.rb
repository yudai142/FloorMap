class SessionsController < ApplicationController
  before_action :authenticate_user!, except: [ :check_in_form, :check_in ]

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
    unless seat
      return respond_to do |format|
        format.html { redirect_to sessions_path, alert: "座席が見つかりません" }
        format.json { render json: { error: "座席が見つかりません" }, status: :not_found }
      end
    end

    session = Session.create(
      user_id: current_user&.id,
      seat_id: seat.id,
      check_in_time: Time.current,
      status: "active"
    )

    if session.persisted?
      respond_to do |format|
        format.html { redirect_to sessions_path, notice: "チェックインしました" }
        format.json { render json: seat.canvas_data, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :check_in_form, alert: "チェックインに失敗しました" }
        format.json { render json: { errors: session.errors }, status: :unprocessable_entity }
      end
    end
  end

  def check_out
    @session = Session.find_by(id: params[:session_id])
    unless @session
      return respond_to do |format|
        format.html { redirect_to sessions_path, alert: "セッションが見つかりません" }
        format.json { render json: { error: "セッションが見つかりません" }, status: :not_found }
      end
    end

    unless @session.user_id == current_user.id || current_user.admin?
      return respond_to do |format|
        format.html { redirect_to sessions_path, alert: "権限がありません" }
        format.json { render json: { error: "権限がありません" }, status: :forbidden }
      end
    end

    if @session.check_out!
      respond_to do |format|
        format.html { redirect_to sessions_path, notice: "チェックアウトしました" }
        format.json { render json: @session.seat.canvas_data, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to sessions_path, alert: "チェックアウトに失敗しました" }
        format.json { render json: { error: "チェックアウトに失敗しました" }, status: :unprocessable_entity }
      end
    end
  end

  def history
    @sessions = if current_user
      current_user.sessions.completed.recent.page(params[:page])
    else
      Session.none
    end
  end

end
