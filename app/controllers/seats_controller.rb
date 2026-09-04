class SeatsController < ApplicationController
  before_action :set_room
  before_action :set_seat, only: [ :show, :edit, :update, :destroy, :position ]

  def index
    authorize Seat.new(room: @room)
    @seats = @room.seats
  end

  def export
    authorize Seat.new(room: @room)
    exporter = SeatExporter.new(@room)
    send_data exporter.to_csv, filename: "#{@room.name}_seats_#{Time.current.strftime("%Y%m%d_%H%M%S")}.csv", type: "text/csv; charset=utf-8"
  end

  def show
    authorize @seat
  end

  def new
    @seat = @room.seats.build
    authorize @seat
  end

  def edit
    authorize @seat
  end

  def create
    attrs = seat_params
    if attrs[:row_number].blank? && attrs[:column_number].blank? &&
       attrs[:position_x].present? && attrs[:position_y].present?
      attrs = attrs.merge(Seat.grid_position_for(position_x: attrs[:position_x], position_y: attrs[:position_y]))
    end
    @seat = @room.seats.build(attrs)
    authorize @seat

    if @seat.save
      respond_to do |format|
        format.html { redirect_to room_seats_path(@room), notice: "座席を作成しました" }
        format.json { render json: @seat.canvas_data, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @seat.errors }, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @seat

    if @seat.update(seat_params)
      redirect_to room_seats_path(@room), notice: "座席を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @seat
    @seat.destroy

    respond_to do |format|
      format.html { redirect_to room_seats_path(@room), notice: "座席を削除しました" }
      format.json { head :no_content }
    end
  end

  def position
    authorize @seat

    if @seat.update(position_params)
      render json: @seat.canvas_data, status: :ok
    else
      render json: { errors: @seat.errors }, status: :unprocessable_entity
    end
  end

  def batch_position
    authorize @room, :update?
    seats = @room.seats.where(id: batch_position_params.keys)

    updated_seats = seats.map do |seat|
      position = batch_position_params[seat.id.to_s]
      seat.update(position_x: position["x"], position_y: position["y"])
      seat
    end

    render json: updated_seats.map(&:canvas_data), status: :ok
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_seat
    @seat = @room.seats.find(params[:id])
  end

  def seat_params
    params.require(:seat).permit(:row_number, :column_number, :seat_type, :position_x, :position_y)
  end

  def position_params
    params.require(:seat).permit(:position_x, :position_y)
  end

  def batch_position_params
    params.require(:positions).permit!.to_h
  end
end
