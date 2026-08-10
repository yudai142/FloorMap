require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:user) { create(:user) }
  let(:manager) { create(:user, :manager) }
  let(:room) { create(:room, user: manager) }

  describe 'validations' do
    it 'is valid with all required attributes' do
      notification = build(:notification, user: user, room: room)
      expect(notification).to be_valid
    end

    it 'is invalid without user_id' do
      notification = build(:notification, user: nil, room: room)
      expect(notification).not_to be_valid
    end

    it 'is invalid without room_id' do
      notification = build(:notification, user: user, room: nil)
      expect(notification).not_to be_valid
    end

    it 'is invalid without notification_type' do
      notification = build(:notification, user: user, room: room, notification_type: nil)
      expect(notification).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:unread_notif) { create(:notification, user: user, room: room, read_at: nil) }
    let!(:read_notif) { create(:notification, user: user, room: room, read_at: Time.current) }

    it '.unread returns only unread notifications' do
      expect(Notification.unread).to include(unread_notif)
      expect(Notification.unread).not_to include(read_notif)
    end

    it '.read returns only read notifications' do
      expect(Notification.read).to include(read_notif)
      expect(Notification.read).not_to include(unread_notif)
    end
  end

  describe '#unread?' do
    it 'returns true when read_at is nil' do
      notification = create(:notification, user: user, room: room, read_at: nil)
      expect(notification.unread?).to be_truthy
    end

    it 'returns false when read_at is set' do
      notification = create(:notification, user: user, room: room, read_at: Time.current)
      expect(notification.unread?).to be_falsey
    end
  end

  describe '#mark_as_read!' do
    it 'sets read_at to current time' do
      notification = create(:notification, user: user, room: room, read_at: nil)
      notification.mark_as_read!

      expect(notification.reload.read_at).not_to be_nil
    end
  end

  describe 'notification types' do
    it 'accepts check_in type' do
      notification = create(:notification, user: user, room: room, notification_type: :check_in)
      expect(notification.check_in?).to be_truthy
    end

    it 'accepts check_out type' do
      notification = create(:notification, user: user, room: room, notification_type: :check_out)
      expect(notification.check_out?).to be_truthy
    end

    it 'accepts system_update type' do
      notification = create(:notification, user: user, room: room, notification_type: :system_update)
      expect(notification.system_update?).to be_truthy
    end

    it 'accepts warning type' do
      notification = create(:notification, user: user, room: room, notification_type: :warning)
      expect(notification.warning?).to be_truthy
    end
  end
end
