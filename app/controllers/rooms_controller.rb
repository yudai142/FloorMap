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
      current_user: current_user.as_json(only: [:id, :email, :role]),
      auth: {
        user: current_user&.slice(:id, :email),
        is_authenticated: user_signed_in?
      }
    }
  end

  def show
    authorize @room

    render inertia: 'Rooms/Show', props: {
      room: {
        id: @room.id,
        name: safe_encode(@room.name),
        description: safe_encode(@room.description),
        width: @room.width || 1000,
        height: @room.height || 700,
        user_id: @room.user_id,
        seats_count: @room.seats.count,
        occupied_count: @room.occupied_seat_count,
        occupancy_rate: @room.occupancy_rate,
        created_at: @room.created_at,
        floor_plan_data: @room.floor_plan_data || []
      },
      seats: @room.seats.map { |s| seat_canvas_json(s) },
      current_user: {
        id: current_user.id,
        email: safe_encode(current_user.email),
        role: current_user.role
      },
      auth: {
        user: {
          id: current_user.id,
          email: safe_encode(current_user.email)
        },
        is_authenticated: user_signed_in?
      }
    }
  end

  def new
    authorize Room, :create?
    @room = Room.new

    render inertia: 'Rooms/New', props: {
      room: {
        id: nil,
        name: '',
        description: ''
      },
      auth: {
        user: current_user&.slice(:id, :email),
        is_authenticated: user_signed_in?
      }
    }
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
      current_user: current_user.as_json(only: [:id, :email]),
      auth: {
        user: current_user&.slice(:id, :email),
        is_authenticated: user_signed_in?
      }
    }
  end

  def canvas_data
    authorize @room, :show?

    sessions = Session.active.joins(:seat).where(seats: { room_id: @room.id })

    render json: {
      room: @room.as_json(only: [ :id, :name, :description ]),
      seats: @room.seats.map(&:canvas_data),
      sessions: sessions.map do |s|
        {
          id: s.id,
          seat_id: s.seat_id,
          status: s.status,
          user_id: s.user_id,
          user: s.user ? {
            id: s.user.id,
            email: s.user.email.to_s.force_encoding('UTF-8'),
            username: s.user.email.to_s.split('@').first.force_encoding('UTF-8')
          } : nil,
          visitor_id: s.visitor_id,
          visitor: s.visitor ? { id: s.visitor.id, display_name: s.visitor.display_name.to_s.force_encoding('UTF-8') } : nil
        }
      end,
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

  def seat_show_json(seat)
    {
      id: seat.id,
      seat_identifier: seat.seat_identifier,
      position_x: seat.position_x,
      position_y: seat.position_y,
      seat_type: seat.seat_type,
      row_number: seat.row_number,
      column_number: seat.column_number,
      room_id: seat.room_id
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

  private

  def safe_encode(str)
    return nil if str.nil?
    str.to_s.encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue => e
    ""
  end
end
