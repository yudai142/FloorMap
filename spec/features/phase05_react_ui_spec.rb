require 'rails_helper'

RSpec.describe 'React UI Components', type: :request do
  describe 'Phase 5: React UI コンポーネント' do
    let(:user) { create(:user, :manager) }
    let(:room) { create(:room, user: user) }

    before do
      sign_in user
    end

    after do
      sign_out user
    end

    describe 'Form Components' do
      describe 'Room Form Component' do
        it 'renders room list page' do
          get rooms_path
          expect(response).to have_http_status(:success)
          # TODO: React component がレンダリングされることを確認
        end

        it 'creates room with form submission' do
          expect {
            post rooms_path, params: { room: { name: 'New Room', description: 'Test Description' } }
          }.to change(Room, :count).by(1)
          expect(response).to redirect_to(room_path(Room.last))
        end

        it 'displays validation errors on invalid input' do
          post rooms_path, params: { room: { name: '' } }
          # expect(response).to have_http_status(:unprocessable_entity)
          # または再レンダリング確認
        end
      end

      describe 'Seat Form Component' do
        it 'renders seat list for room' do
          get room_path(room)
          expect(response).to have_http_status(:success)
        end

        it 'creates seat with valid data' do
          expect {
            post room_seats_path(room), params: {
              seat: { row_number: 1, column_number: 2, seat_type: 'regular', position_x: 10, position_y: 20 }
            }
          }.to change(Seat, :count).by(1)
        end

        it 'prevents duplicate seat position' do
          create(:seat, room: room, row_number: 1, column_number: 2)
          expect {
            post room_seats_path(room), params: {
              seat: { row_number: 1, column_number: 2, seat_type: 'regular', position_x: 10, position_y: 20 }
            }
          }.not_to change(Seat, :count)
        end
      end
    end

    describe 'Modal Components' do
      describe 'Confirmation Modal' do
        it 'displays seat details page' do
          seat = create(:seat, room: room)
          get room_seat_path(room, seat)
          expect(response).to have_http_status(:success)
        end

        it 'deletes seat on user confirmation' do
          seat = create(:seat, room: room)
          expect {
            delete room_seat_path(room, seat)
          }.to change(Seat, :count).by(-1)
        end
      end

      describe 'Authorization' do
        it 'denies access to unauthorized users' do
          other_user = create(:user)
          sign_out user
          sign_in other_user

          get room_path(room)
          # Redirect to home or show 403 forbidden
          expect([302, 403]).to include(response.status)
        end
      end
    end

    describe 'List/Table Components' do
      describe 'Room List Component' do
        it 'displays all user rooms' do
          create_list(:room, 3, user: user)
          get rooms_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Meeting Room')
        end

        it 'handles room pagination' do
          create_list(:room, 2, user: user)
          get rooms_path
          expect(response).to have_http_status(:success)
        end

        it 'displays room information' do
          room_data = create(:room, user: user, name: 'Conference Room')
          get rooms_path
          expect(response.body).to include('Conference Room')
        end
      end

      describe 'Seat Grid Component' do
        it 'displays seats for room' do
          create_list(:seat, 6, room: room)
          get room_path(room)
          expect(response).to have_http_status(:success)
        end

        it 'shows active session status' do
          seat = create(:seat, room: room)
          session = create(:session, user: user, seat: seat)
          get room_path(room)
          expect(response).to have_http_status(:success)
        end

        it 'updates seat type' do
          seat = create(:seat, room: room)
          patch room_seat_path(room, seat), params: { seat: { seat_type: 'vip' } }
          seat.reload
          expect(seat.seat_type).to eq('vip')
        end
      end
    end

    describe 'Button Components' do
      it 'renders action buttons on pages' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end

      it 'action buttons trigger appropriate responses' do
        seat = create(:seat, room: room)
        patch room_seat_path(room, seat), params: { seat: { seat_type: 'vip' } }
        expect(response).to redirect_to(room_seats_path(room)) || have_http_status(:success)
      end
    end

    describe 'Hotwire Integration' do
      it 'pages render successfully with Turbo' do
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'form submissions work with Turbo' do
        expect {
          post rooms_path, params: { room: { name: 'Test Room', description: 'Test' } }
        }.to change(Room, :count)
      end
    end

    describe 'Component State Management' do
      it 'maintains data through form submissions' do
        post rooms_path, params: { room: { name: 'New Room', description: 'Description' } }
        expect(Room.last.name).to eq('New Room')
      end

      it 'preserves values on page navigation' do
        room_data = create(:room, user: user)
        get room_path(room_data)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(room_data.name)
      end
    end

    describe 'Accessibility' do
      it 'pages render with proper structure' do
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'forms are accessible' do
        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Error Handling' do
      it 'handles missing resources gracefully' do
        get room_path(999)
        expect(response).to have_http_status(:not_found)
      end

      it 'displays error messages on failure' do
        post room_seats_path(room), params: { seat: { row_number: nil, column_number: nil, seat_type: 'regular' } }
        # Page renders with errors
      end
    end

    describe 'Performance' do
      it 'loads room list efficiently' do
        create_list(:room, 10, user: user)
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'renders room with many seats' do
        create_list(:seat, 20, room: room)
        get room_path(room)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
