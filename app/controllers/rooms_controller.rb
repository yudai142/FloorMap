class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy, :canvas_data, :canvas_editor, :floor_plan ]

  def index
    authorize Room
    @rooms = policy_scope(Room)
    @rooms = @rooms.search(params[:search]) if params[:search].present?
    @rooms = @rooms.by_owner(params[:owner_id]) if params[:owner_id].present?
    @rooms = @rooms.sorted(params[:sort], params[:direction]) if params[:sort].present?

    render inertia: 'Rooms/Index', props: {
      rooms: @rooms.map { |r| room_index_json(r) },
      current_user: current_user.as_json(only: [:id, :email, :role])
    }
  end

  def show
    authorize @room
  end

  def new
    authorize Room, :create?
    @room = Room.new

    respond_to do |format|
      format.html { render :new }
      format.json { render json: { room: @room } }
    end
  end

  def create
    @room = current_user.rooms.build(room_params)
    authorize @room

    if @room.save
      respond_to do |format|
        format.html { redirect_to @room, notice: "ルームを作成しました" }
        format.json { render json: @room, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @room.errors.messages }, status: :unprocessable_entity }
      end
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
    authorize @room, :canvas_editor?

    render inertia: 'Rooms/CanvasEditor', props: {
      room: {
        id: @room.id,
        name: @room.name,
        description: @room.description,
        width: 1000,  # Default width
        height: 700   # Default height
      },
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

  def room_index_json(room)
    {
      id: room.id,
      name: room.name,
      description: room.description,
      seats_count: room.seats.count,
      occupied_seat_count: room.occupied_seat_count,
      occupancy_rate: room.occupancy_rate,
      created_at: room.created_at
    }
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
