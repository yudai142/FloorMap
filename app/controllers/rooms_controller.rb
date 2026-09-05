class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy, :canvas_data, :canvas_editor, :floor_plan ]

  def index
    authorize Room
    @rooms = policy_scope(Room)
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

  def canvas_editor
    authorize @room, :update?

    render inertia: 'Rooms/CanvasEditor', props: {
      room: @room.as_json(only: [:id, :name, :description, :width, :height]),
      shapes_data: @room.floor_plan_data || [],
      seats: @room.seats.map { |s| seat_canvas_json(s) },
      current_user: current_user.as_json(only: [:id, :email])
    }
  end

  def canvas_data
    authorize @room, :show?

    render json: {
      room: @room.as_json(only: [ :id, :name, :description ]),
      seats: @room.seats.map(&:canvas_data),
      floor_plan_data: @room.floor_plan_data
    }
  end

  def floor_plan
    authorize @room, :update?

    if @room.update(floor_plan_params)
      render json: { floor_plan_data: @room.floor_plan_data }, status: :ok
    else
      render json: { errors: @room.errors }, status: :unprocessable_entity
    end
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

  def seat_canvas_json(seat)
    data = seat.canvas_data
    {
      id: data[:id],
      label: data[:seat_identifier],
      x: data[:position_x] || 0,
      y: data[:position_y] || 0,
      occupied: data[:session].present?,
      occupant_name: data[:session]&.dig(:name) || data[:session]&.dig(:user_id).to_s || "不明",
      seat_type: data[:seat_type]
    }
  end

  def floor_plan_params
    params.require(:room).permit(floor_plan_data: [:type, :x, :y, :width, :height, :color, :lineWidth])
  end
end
