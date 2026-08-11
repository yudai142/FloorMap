require 'rails_helper'

RSpec.describe 'Room Sharing Functionality', type: :request do
  describe 'Issue #67: 共有リンク機能' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }

    before { sign_in user }

    describe 'Generate Share Link' do
      it 'ShareLink model exists' do
        expect(defined?(ShareLink)).to be_truthy
      end

      it 'Share link has unique token' do
        share_link = create(:share_link, room: room)
        expect(share_link.token).to be_present
        expect(share_link.token.length).to eq(32)
      end

      it 'Share link association works' do
        share_link = create(:share_link, room: room)
        expect(room.share_links).to include(share_link)
      end

      it 'Share link validates token presence' do
        link = ShareLink.new(room: room, token: nil)
        expect(link).not_to be_valid
      end
    end

    describe 'Share Link with Expiry' do
      pending 'Share link can have expiry date' do
        post room_share_links_path(room), params: {
          share_link: { expires_at: 7.days.from_now }
        }
        expect(response).to have_http_status(:created)
      end

      pending 'Expired share link is not accessible' do
        share_link = create(:share_link, room: room, expires_at: 1.day.ago)
        sign_out user
        get room_path(room, token: share_link.token)
        expect(response).to have_http_status(:unauthorized)
      end

      pending 'Remaining time is shown for active share link' do
        share_link = create(:share_link, room: room, expires_at: 7.days.from_now)
        sign_out user
        get room_path(room, token: share_link.token)
        expect(response.body).to include('残り時間')
      end
    end

    describe 'QR Code Generation' do
      pending 'QR code is generated for share link' do
        share_link = create(:share_link, room: room)
        get share_link_qr_code_path(share_link), as: :image
        expect(response.content_type).to include('image/')
      end

      pending 'QR code encodes share link URL' do
        share_link = create(:share_link, room: room)
        get share_link_qr_code_path(share_link), as: :image
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'Authorization' do
      pending 'Only manager can create share link' do
        visitor = create(:user)
        sign_in visitor
        post room_share_links_path(room)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
