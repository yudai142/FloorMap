class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @unread_notifications = current_user.notifications.unread
    @read_notifications = current_user.notifications.read
  end

  def mark_all_as_read
    current_user.notifications.unread.each(&:mark_as_read!)
    redirect_to notifications_path, notice: "すべての通知を既読にしました"
  end
end
