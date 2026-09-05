class RoomsChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    authorize_room(room)
    stream_for room
  end

  def unsubscribed
  end

  private

  def authorize_room(room)
    return if current_user.owner_of?(room) || current_user.has_permission_in?(room) || current_user.admin?

    reject
  end
end
