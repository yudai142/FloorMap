require 'rails_helper'

RSpec.describe 'rooms/show', type: :view do
  let(:manager) { create(:user, :manager) }
  let(:user) { create(:user) }
  let(:room) { create(:room, user: manager, name: 'Meeting Room A', description: 'Test room') }

  before do
    assign(:room, room)
    allow(view).to receive(:current_user).and_return(manager)
  end

  context 'when user is authorized' do
    it 'displays room title' do
      render
      expect(rendered).to include('Meeting Room A')
    end

    it 'displays room description' do
      render
      expect(rendered).to include('Test room')
    end

    it 'displays seat count' do
      create_list(:seat, 5, room: room)
      assign(:room, room.reload)
      render
      expect(rendered).to include('5')
    end

    it 'displays seats grid layout' do
      create(:seat, room: room, row_number: 0, column_number: 1, seat_type: 'regular')
      create(:seat, room: room, row_number: 0, column_number: 2, seat_type: 'accessible')
      assign(:room, room.reload)
      render
      expect(rendered).to include('A1')
      expect(rendered).to include('A2')
    end

    it 'shows edit and delete buttons for owner' do
      render
      expect(rendered).to include('編集')
      expect(rendered).to include('削除')
    end
  end

  context 'when user is not authorized' do
    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'does not show edit button' do
      render
      expect(rendered).not_to include('編集')
    end
  end

  describe 'seat grid display' do
    it 'shows all seats in grid format' do
      create(:seat, room: room, row_number: 0, column_number: 1)
      create(:seat, room: room, row_number: 0, column_number: 2)
      create(:seat, room: room, row_number: 1, column_number: 1)
      assign(:room, room.reload)
      render
      expect(rendered).to match(/座席配置/)
    end

    it 'distinguishes seat types with badges' do
      create(:seat, room: room, seat_type: 'regular')
      create(:seat, room: room, seat_type: 'accessible')
      create(:seat, room: room, seat_type: 'vip')
      assign(:room, room.reload)
      render
      expect(rendered).to include('通常座席')
    end
  end
end
