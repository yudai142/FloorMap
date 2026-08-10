class RoomsController < ApplicationController
  before_action :set_room, only: [ :show, :edit, :update, :destroy ]

  def index
    @rooms = current_user.rooms
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

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :description)
  end
end
