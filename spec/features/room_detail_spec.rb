require 'rails_helper'

RSpec.describe 'Room Detail Page', type: :feature do
  let(:manager) { create(:user, :manager) }
  let(:user) { create(:user) }
  let(:room) { create(:room, user: manager, name: 'Test Room', description: 'A test room') }

  before do
    create_list(:seat, 10, room: room)
  end

  context 'when user is owner' do
    before do
      login_as(manager)
    end

    it 'displays room details' do
      visit room_path(room)
      expect(page).to have_content('Test Room')
      expect(page).to have_content('A test room')
    end

    it 'displays seat count' do
      visit room_path(room)
      expect(page).to have_content('10')
    end

    it 'displays edit button' do
      visit room_path(room)
      expect(page).to have_link('編集')
    end

    it 'displays delete button' do
      visit room_path(room)
      expect(page).to have_link('削除')
    end

    it 'displays seat grid' do
      visit room_path(room)
      expect(page).to have_content('座席配置')
    end
  end

  context 'when user is not authorized' do
    before do
      login_as(user)
    end

    it 'shows access denied message' do
      visit room_path(room)
      expect(page).to have_content('ホーム')
    end
  end

  describe 'seat information display' do
    before do
      login_as(manager)
      create(:session, seat: room.seats.first, status: :active, user: user)
    end

    it 'shows occupied seat status' do
      visit room_path(room)
      expect(page).to have_content('使用中')
    end

    it 'shows user info for occupied seats' do
      visit room_path(room)
      expect(page).to have_content(user.email)
    end
  end

  describe 'seat type filtering' do
    before do
      login_as(manager)
      create(:seat, room: room, seat_type: 'accessible')
      create(:seat, room: room, seat_type: 'vip')
    end

    it 'displays different seat types' do
      visit room_path(room)
      expect(page).to have_content('通常座席')
      expect(page).to have_content('障害対応')
      expect(page).to have_content('VIP座席')
    end
  end
end
