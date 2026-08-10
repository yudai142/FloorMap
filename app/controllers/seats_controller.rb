class SeatsController < ApplicationController
  before_action :set_room
  before_action :set_seat, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Seat.new(room: @room)
    @seats = @room.seats
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
    @seat = @room.seats.build(seat_params)
    authorize @seat

    if @seat.save
      redirect_to room_seats_path(@room), notice: "座席を作成しました"
    else
      render :new, status: :unprocessable_entity
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

    redirect_to room_seats_path(@room), notice: "座席を削除しました"
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_seat
    @seat = @room.seats.find(params[:id])
  end

  def seat_params
    params.require(:seat).permit(:row_number, :column_number, :seat_type)
  end
end
