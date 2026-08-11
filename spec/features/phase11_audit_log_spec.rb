require 'rails_helper'

RSpec.describe 'Audit Log Functionality', type: :request do
  describe 'Issue #68: 監査ログ・操作履歴（PaperTrail）' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }

    before { sign_in user }

    describe 'Room Change History' do
      pending 'Room updates are recorded in Version table' do
        expect {
          room.update(name: 'Updated Room Name')
        }.to change { PaperTrail::Version.count }.by(1)
      end

      pending 'Version record contains user information' do
        room.update(name: 'Updated Room Name')
        version = PaperTrail::Version.last
        expect(version.whodunnit).to eq(user.id.to_s)
      end

      pending 'Version record contains change details' do
        room.update(name: 'Updated Room Name', capacity: 50)
        version = PaperTrail::Version.last
        expect(version.changes).to include('name', 'capacity')
      end
    end

    describe 'Seat Change History' do
      let(:seat) { create(:seat, room: room) }

      pending 'Seat updates are recorded in Version table' do
        expect {
          seat.update(status: :unavailable)
        }.to change { PaperTrail::Version.count }.by(1)
      end

      pending 'Seat deletion is recorded as destroy version' do
        expect {
          seat.destroy
        }.to change { PaperTrail::Version.count }
      end
    end

    describe 'History Audit Page' do
      pending 'GET /rooms/:id/audit_log shows change history' do
        room.update(name: 'Updated')
        get room_audit_log_path(room)
        expect(response).to have_http_status(:ok)
      end

      pending 'Audit log displays user, timestamp, and changes' do
        room.update(name: 'Updated')
        get room_audit_log_path(room)
        expect(response.body).to include(user.email, 'Updated')
      end

      pending 'Audit log is sortable by timestamp' do
        3.times { |i| room.update(name: "Update #{i}") }
        get room_audit_log_path(room), params: { sort: 'newest' }
        expect(response).to have_http_status(:ok)
      end

      pending 'Only manager can view audit log' do
        visitor = create(:user)
        sign_in visitor
        get room_audit_log_path(room)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'Version Restoration' do
      pending 'Previous version of room can be restored' do
        original_name = room.name
        room.update(name: 'Temporary Name')

        version = PaperTrail::Version.last
        version.reify.save

        expect(room.reload.name).to eq(original_name)
      end
    end
  end
end
