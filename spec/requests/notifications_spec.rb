require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }

  describe "#mark_all_as_read behavior" do
    it "marks all unread notifications as read" do
      sign_in user
      notification1 = create(:notification, user: user, room: room, notification_type: :check_in, read_at: nil)
      notification2 = create(:notification, user: user, room: room, notification_type: :check_out, read_at: nil)

      expect {
        patch mark_all_as_read_notifications_path
      }.to change { notification1.reload.read_at }.from(nil).to(kind_of(ActiveSupport::TimeWithZone))

      expect(notification2.reload.read_at).not_to be_nil
    end
  end
end
