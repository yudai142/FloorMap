class SessionsController < ApplicationController
  before_action :authenticate_user!, except: [ :check_in_form, :check_in, :check_out ]

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

    session = nil
    checkout_timer_minutes = params[:checkout_timer_minutes]&.to_i || 60

    begin
      ActiveRecord::Base.transaction do
        if current_user
          # Check out any existing active session for this user
          existing_session = Session.active.where(user_id: current_user.id).first
          existing_session.check_out! if existing_session

          session = Session.create!(
            user_id: current_user.id,
            seat_id: seat.id,
            check_in_time: Time.current,
            status: "active",
            checkout_timer_minutes: checkout_timer_minutes,
            user_auto_checkout_enabled: current_user.auto_checkout_enabled,
            user_auto_checkout_time: current_user.auto_checkout_time
          )
        else
          # Create visitor for unauthenticated users
          visitor = Visitor.create!(nickname: "Anonymous User #{SecureRandom.hex(4)}")
          session = Session.create!(
            visitor_id: visitor.id,
            seat_id: seat.id,
            check_in_time: Time.current,
            status: "active",
            checkout_timer_minutes: checkout_timer_minutes
          )
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      session = e.record
    end

    if session&.persisted?
      respond_to do |format|
        format.html { redirect_to sessions_path, notice: "チェックインしました" }
        format.json { render json: { id: session.id, seat_id: session.seat_id, status: session.status }, status: :created }
      end
    else
      error_message = if session&.errors&.any?
        session.errors.full_messages.join(", ")
      else
        "チェックインに失敗しました"
      end
      respond_to do |format|
        format.html { render :check_in_form, alert: error_message }
        format.json { render json: { message: error_message }, status: :unprocessable_entity }
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

    # Check authorization: allow if user owns the session or is admin
    if current_user
      unless @session.user_id == current_user.id || current_user.admin?
        return respond_to do |format|
          format.html { redirect_to sessions_path, alert: "権限がありません" }
          format.json { render json: { error: "権限がありません" }, status: :forbidden }
        end
      end
    end
    # Allow unauthenticated users to check out (no authorization check)

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
