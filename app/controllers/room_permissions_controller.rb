class RoomPermissionsController < ApplicationController
  before_action :set_room_permission, only: :destroy

  def create
    @room = Room.find(params[:room_id])
    @room_permission = @room.room_permissions.build(room_permission_params)
    authorize @room_permission, :create?

    if @room_permission.save
      redirect_to @room, notice: "権限を付与しました"
    else
      redirect_to @room, alert: "権限の付与に失敗しました"
    end
  end

  def destroy
    authorize @room_permission, :destroy?
    @room = @room_permission.room
    @room_permission.destroy
    redirect_to @room, notice: "権限を削除しました"
  end

  private

  def set_room_permission
    @room_permission = RoomPermission.find(params[:id])
  end

  def room_permission_params
    params.require(:room_permission).permit(:user_id, :user_email, :permission_type)
  end
end
