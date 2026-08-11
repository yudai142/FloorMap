class VisitorsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_or_create_visitor, only: [ :edit, :update, :check_out ]
  before_action :set_room, only: [ :check_in ]
  before_action :set_seat, only: [ :check_in ]

  def check_in
    @visitor = find_or_create_visitor
    @room = @seat.room if @seat
  end

  def create_check_in
    @visitor = find_or_create_visitor
    @seat = Seat.find(params[:seat_id])

    if @visitor.check_in_to_seat(@seat)
      session[:visitor_id] = @visitor.id
      redirect_to @seat.room, notice: "チェックインしました"
    else
      redirect_to check_in_visitors_path(seat_id: @seat.id), alert: "チェックイン失敗"
    end
  end

  def check_out
    if @visitor.check_out
      session.delete(:visitor_id)
      redirect_to root_path, notice: "チェックアウトしました"
    else
      redirect_to root_path, alert: "チェックアウト失敗"
    end
  end

  def edit
    @room = @visitor.current_room
  end

  def update
    if @visitor.update(visitor_params)
      broadcast_visitor_updated
      redirect_to @visitor.current_room, notice: "ニックネームが更新されました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_or_create_visitor
    if session[:visitor_id]
      Visitor.find(session[:visitor_id])
    else
      session_id = session.id
      Visitor.find_or_create_by(session_id: session_id) do |visitor|
        visitor.nickname = "訪問者#{rand(1000..9999)}"
      end
    end
  end

  def set_or_create_visitor
    @visitor = find_or_create_visitor
  end

  def set_room
    @room = Room.find(params[:room_id]) if params[:room_id]
  end

  def set_seat
    @seat = Seat.find(params[:seat_id]) if params[:seat_id]
  end

  def visitor_params
    params.require(:visitor).permit(:nickname)
  end

  def broadcast_visitor_updated
    @visitor.current_room&.sessions&.each do |session|
      RoomsChannel.broadcast_to(@visitor.current_room, {
        type: "visitor_updated",
        visitor_id: @visitor.id,
        nickname: @visitor.nickname
      })
    end
  end
end
