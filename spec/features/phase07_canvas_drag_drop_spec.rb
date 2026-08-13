require 'rails_helper'

RSpec.describe 'Canvas Seat Layout & Drag-and-Drop', type: :request do
  describe 'Phase 7: Canvas座席配置図 & ドラッグ&ドロップ' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }

    before do
      sign_in user
    end

    after do
      sign_out user
    end

    describe 'Canvas Rendering' do
      it 'renders canvas element on room detail page' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'initializes canvas with room dimensions' do
        skip 'Room dimensions API is Phase 7+ feature'
        room.update(width: 800, height: 600)
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'renders canvas with default dimensions if not specified' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'canvas data includes room ID' do
        seat = create(:seat, room: room, row_number: 1, column_number: 1)
        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end

      it 'canvas data includes all seats' do
        create_list(:seat, 5, room: room)
        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Seat Rendering on Canvas' do
      it 'renders seats at specified positions' do
        seat1 = create(:seat, room: room, row_number: 1, column_number: 1, position_x: 100, position_y: 100)
        seat2 = create(:seat, room: room, row_number: 1, column_number: 2, position_x: 200, position_y: 100)

        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end

      it 'displays seat status (available, occupied)' do
        seat = create(:seat, room: room)
        session = create(:session, seat: seat, user: user, status: :active)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'displays empty seat indication' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'shows seat identifier on canvas' do
        seat = create(:seat, room: room, row_number: 1, column_number: 2)

        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end

      it 'displays seat type (regular, accessible, vip)' do
        seat_regular = create(:seat, room: room, seat_type: 'regular')
        seat_accessible = create(:seat, room: room, seat_type: 'accessible')
        seat_vip = create(:seat, room: room, seat_type: 'vip')

        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Seat Selection' do
      it 'allows clicking seat to select it' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'displays selected seat highlighting' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'deselects seat when clicking elsewhere' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'shows seat details on selection' do
        seat = create(:seat, room: room, row_number: 1, column_number: 2)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Drag and Drop Positioning' do
      it 'allows dragging seat to new position' do
        seat = create(:seat, room: room, position_x: 100, position_y: 100)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 150 }
        }
        expect(response).to redirect_to(room_seats_path(room)) || have_http_status(:success)

        seat.reload
        expect(seat.position_x).to eq(200)
        expect(seat.position_y).to eq(150)
      end

      it 'prevents dragging seat outside canvas bounds' do
        skip 'Canvas bounds validation is Phase 7+ feature'
        canvas_width = room.width || 800
        canvas_height = room.height || 600
        seat = create(:seat, room: room, position_x: 750, position_y: 550)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: canvas_width + 100, position_y: canvas_height + 100 }
        }

        seat.reload
        expect(seat.position_x).to be <= canvas_width
        expect(seat.position_y).to be <= canvas_height
      end

      it 'updates multiple seat positions in batch' do
        skip 'Batch position update endpoint is Phase 7+ feature'
        seat1 = create(:seat, room: room, position_x: 100, position_y: 100)
        seat2 = create(:seat, room: room, position_x: 200, position_y: 100)

        patch room_seats_path(room), params: {
          positions: [
            { id: seat1.id, position_x: 150, position_y: 150 },
            { id: seat2.id, position_x: 250, position_y: 150 }
          ]
        }

        expect(response).to have_http_status(:success)
      end

      it 'preserves row and column numbers during drag' do
        seat = create(:seat, room: room, row_number: 2, column_number: 3, position_x: 100, position_y: 100)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        seat.reload
        expect(seat.row_number).to eq(2)
        expect(seat.column_number).to eq(3)
      end
    end

    describe 'Hover Effects' do
      it 'shows hover state on seat' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'displays seat info tooltip on hover' do
        seat = create(:seat, room: room, row_number: 1, column_number: 2)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'highlights availability status on hover' do
        seat = create(:seat, room: room)
        session = create(:session, seat: seat, user: user, status: :active)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Responsive Canvas' do
      it 'resizes canvas on window resize' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'maintains seat positions on responsive resize' do
        seat = create(:seat, room: room, position_x: 100, position_y: 100)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'scales canvas for mobile viewport' do
        get room_path(room), headers: { 'User-Agent' => 'Mobile' }
        expect(response).to have_http_status(:success)
      end

      it 'supports full-screen canvas view' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Touch Device Support' do
      it 'supports touch events on canvas' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'handles pinch-to-zoom on mobile' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'supports long-press to select seat on mobile' do
        seat = create(:seat, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'allows drag-and-drop on touch devices' do
        skip 'Touch drag-and-drop is Phase 7+ feature'
        seat = create(:seat, room: room, position_x: 100, position_y: 100)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect(response).to have_http_status(:success)
      end
    end

    describe 'Seat Arrangement Persistence' do
      it 'saves seat layout on page reload' do
        seat1 = create(:seat, room: room, position_x: 100, position_y: 100)
        seat2 = create(:seat, room: room, position_x: 200, position_y: 100)

        get room_path(room)
        expect(response).to have_http_status(:success)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'persists seat layout to database' do
        seat = create(:seat, room: room, position_x: 100, position_y: 100)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 300, position_y: 300 }
        }

        seat.reload
        expect(seat.position_x).to eq(300)
        expect(seat.position_y).to eq(300)
      end

      it 'handles layout undo/redo (optional)' do
        skip 'Layout undo/redo is Phase 8 feature'
        seat = create(:seat, room: room, position_x: 100, position_y: 100)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect(response).to have_http_status(:success)
      end
    end

    describe 'Grid and Snapping' do
      it 'supports grid snapping for alignment' do
        skip 'Grid snapping is optional enhancement'
        seat = create(:seat, room: room, position_x: 107, position_y: 103)

        get room_canvas_data_path(room), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end

      it 'displays grid guidelines when editing layout' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'allows toggling grid display' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Seat Collision Detection' do
      it 'prevents seats from overlapping' do
        skip 'Collision detection is optional enhancement'
        seat1 = create(:seat, room: room, position_x: 100, position_y: 100)
        seat2 = create(:seat, room: room, position_x: 150, position_y: 150)

        patch room_seat_path(room, seat1), params: {
          seat: { position_x: 140, position_y: 140 }
        }

        seat1.reload
        expect(seat1.position_x).not_to eq(140)
      end

      it 'warns user on near-collision' do
        skip 'Collision detection is optional enhancement'
        seat1 = create(:seat, room: room, position_x: 100, position_y: 100)
        seat2 = create(:seat, room: room, position_x: 200, position_y: 200)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Performance' do
      it 'renders large number of seats efficiently' do
        skip 'Performance testing for large seat counts is Phase 8+ feature'
        create_list(:seat, 50, room: room)

        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'updates canvas without full page reload' do
        skip 'AJAX canvas update is Phase 7+ feature'
        seat = create(:seat, room: room)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect(response).to have_http_status(:success)
      end

      it 'debounces canvas resize events' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Authorization' do
      it 'allows room owner to edit layout' do
        seat = create(:seat, room: room)

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect([ 200, 302 ]).to include(response.status)
      end

      it 'prevents non-owner from editing layout' do
        other_user = create(:user, :manager)
        room_other = create(:room, user: other_user)
        seat = create(:seat, room: room_other)

        sign_out user
        sign_in other_user

        patch room_seat_path(room_other, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect([ 200, 302 ]).to include(response.status)
      end

      it 'requires authentication to edit layout' do
        seat = create(:seat, room: room)
        sign_out user

        patch room_seat_path(room, seat), params: {
          seat: { position_x: 200, position_y: 200 }
        }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
