require 'rails_helper'

RSpec.describe 'Seat Canvas Operations', type: :request do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }
  let(:seat) { create(:seat, room: room, position_x: 100, position_y: 100) }

  before do
    sign_in user
  end

  describe 'POST /rooms/:id/seats (Canvas Creation)' do
    context 'with canvas position data (position_x, position_y)' do
      let(:params) do
        {
          seat: {
            position_x: 150,
            position_y: 200,
            seat_type: 'regular'
          }
        }
      end

      it 'creates seat with canvas coordinates' do
        expect {
          post room_seats_path(room), params: params, headers: { 'Accept' => 'application/json' }
        }.to change(Seat, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['id']).to be_present
        expect(json['position_x']).to eq(150)
        expect(json['position_y']).to eq(200)
      end

      it 'calculates grid position from canvas coordinates' do
        post room_seats_path(room), params: params, headers: { 'Accept' => 'application/json' }
        new_seat = Seat.last
        expect(new_seat.position_x).to eq(150)
        expect(new_seat.position_y).to eq(200)
        # row_number and column_number should be calculated
        expect(new_seat.row_number).to be_present
        expect(new_seat.column_number).to be_present
      end

      it 'returns error for duplicate position' do
        seat.update(position_x: 150, position_y: 200)
        post room_seats_path(room), params: params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns JSON response for canvas' do
        post room_seats_path(room), params: params, headers: { 'Accept' => 'application/json' }
        json = JSON.parse(response.body)
        expect(json).to include('id', 'seat_identifier', 'position_x', 'position_y', 'seat_type')
      end
    end

    context 'with grid position data (row_number, column_number)' do
      let(:params) do
        {
          seat: {
            row_number: 1,
            column_number: 1,
            seat_type: 'regular'
          }
        }
      end

      it 'creates seat with grid coordinates' do
        expect {
          post room_seats_path(room), params: params
        }.to change(Seat, :count).by(1)

        new_seat = Seat.last
        expect(new_seat.row_number).to eq(1)
        expect(new_seat.column_number).to eq(1)
      end
    end
  end

  describe 'PATCH /rooms/:id/seats/:id/position (Canvas Move)' do
    context 'with canvas coordinates' do
      let(:params) do
        {
          seat: {
            position_x: 250,
            position_y: 300
          }
        }
      end

      it 'updates seat position' do
        patch room_seat_position_path(room, seat), params: params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        expect(seat.reload.position_x).to eq(250)
        expect(seat.reload.position_y).to eq(300)
      end

      it 'returns updated seat canvas data' do
        patch room_seat_position_path(room, seat), params: params, headers: { 'Accept' => 'application/json' }
        json = JSON.parse(response.body)
        expect(json['position_x']).to eq(250)
        expect(json['position_y']).to eq(300)
      end

      it 'updates grid position based on new coordinates' do
        patch room_seat_position_path(room, seat), params: params, headers: { 'Accept' => 'application/json' }
        expect(seat.reload.row_number).to be_present
        expect(seat.reload.column_number).to be_present
      end

      it 'prevents moving to occupied position' do
        seat2 = create(:seat, room: room, position_x: 250, position_y: 300)
        patch room_seat_position_path(room, seat), params: params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with batch position update' do
      let(:seat2) { create(:seat, room: room, position_x: 200, position_y: 200) }
      let(:params) do
        {
          positions: [
            { seat_id: seat.id, position_x: 100, position_y: 100 },
            { seat_id: seat2.id, position_x: 300, position_y: 300 }
          ]
        }
      end

      it 'updates multiple seats positions' do
        patch room_seats_batch_position_path(room), params: params, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        expect(seat.reload.position_x).to eq(100)
        expect(seat2.reload.position_x).to eq(300)
      end
    end
  end

  describe 'DELETE /rooms/:id/seats/:id (Canvas Delete)' do
    it 'deletes seat' do
      expect {
        delete room_seat_path(room, seat), headers: { 'Accept' => 'application/json' }
      }.to change(Seat, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns JSON response' do
      delete room_seat_path(room, seat), headers: { 'Accept' => 'application/json' }
      json = JSON.parse(response.body)
      expect(json).to include('id', 'deleted')
    end

    it 'prevents deletion by non-owner' do
      other_user = create(:user, :manager)
      sign_out user
      sign_in other_user

      expect {
        delete room_seat_path(room, seat), headers: { 'Accept' => 'application/json' }
      }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe 'Seat Canvas Data Response Format' do
    it 'returns canvas-compatible seat data' do
      get room_canvas_data_path(room)
      json = JSON.parse(response.body)
      seat_data = json['seats'].first

      expect(seat_data).to include(
        'id',
        'seat_identifier',
        'position_x',
        'position_y',
        'seat_type',
        'occupied',
        'occupant_name'
      )
    end

    it 'includes session information in seat data' do
      session = create(:session, user: user, seat: seat)
      get room_canvas_data_path(room)
      json = JSON.parse(response.body)
      seat_data = json['seats'].first

      expect(seat_data['occupied']).to eq(true)
      expect(seat_data['occupant_name']).to be_present
    end
  end
end
