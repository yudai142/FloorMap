class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy, :canvas_data ]

  def index
    authorize Room
    @rooms = policy_scope(Room).includes(:seats)
    @rooms = @rooms.search(params[:search]) if params[:search].present?
    @rooms = @rooms.by_owner(params[:owner_id]) if params[:owner_id].present?
    @rooms = @rooms.sorted(params[:sort], params[:direction]) if params[:sort].present?
  end

  def show
    authorize @room
  end

  def new
    @room = Room.new
    authorize @room
  end

  def create
    @room = current_user.rooms.build(room_params)
    authorize @room

    if @room.save
      redirect_to @room, notice: "ルームを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @room
  end

  def update
    authorize @room

    if @room.update(room_params)
      redirect_to @room, notice: "ルームを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @room
    @room.destroy

    redirect_to rooms_url, notice: "ルームを削除しました"
  end

  def canvas_data
    authorize @room, :show?

    seats_with_sessions = @room.seats.map do |seat|
      session = Session.where(seat_id: seat.id, status: :active).last
      seat.canvas_data.merge(session: session&.as_json(only: [ :id, :user_id, :check_in_time ]))
    end

    render json: {
      room: @room.as_json(only: [ :id, :name, :description ]),
      seats: seats_with_sessions
    }
  end

  def export
    exporter = RoomExporter.new(current_user)
    send_data exporter.to_csv, filename: "rooms_#{Time.current.strftime("%Y%m%d_%H%M%S")}.csv", type: "text/csv; charset=utf-8"
  end

  private

  def set_room
    @room = Room.find(params[:id] || params[:room_id])
  end

  def room_params
    params.require(:room).permit(:name, :description)
  end
end
