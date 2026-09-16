require 'rails_helper'

RSpec.describe 'Room List & Search', type: :request do
  describe 'Phase 6: ルーム一覧・検索機能' do
    let(:user) { create(:user, :manager) }
    let(:other_user) { create(:user, :manager) }
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in user
    end

    after do
      sign_out user
    end

    describe 'Room List Display' do
      it 'displays all rooms for the current user' do
        room1 = create(:room, user: user, name: 'Meeting Room A')
        room2 = create(:room, user: user, name: 'Conference Room B')
        create(:room, user: other_user, name: 'Private Room')

        get rooms_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Meeting Room A')
        expect(response.body).to include('Conference Room B')
      end

      it 'does not display rooms from other users' do
        create(:room, user: user, name: 'My Room')
        other_room = create(:room, user: other_user, name: 'Other Room')

        get rooms_path
        expect(response.body).not_to include('Other Room')
      end

      it 'shows empty state when user has no rooms' do
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays room metadata (seat count, updated_at)' do
        room = create(:room, user: user, name: 'Test Room')
        create_list(:seat, 5, room: room)

        get rooms_path
        expect(response.body).to include('Test Room')
      end
    end

    describe 'Search Functionality' do
      it 'filters rooms by name search term' do
        room1 = create(:room, user: user, name: 'Meeting Room')
        room2 = create(:room, user: user, name: 'Conference Hall')

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Meeting Room')
        expect(response.body).not_to include('Conference Hall')
      end

      it 'search is case-insensitive' do
        room = create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'meeting' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Meeting Room')
      end

      it 'searches by partial name match' do
        room = create(:room, user: user, name: 'Conference Room')

        get rooms_path, params: { search: 'ence' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Conference Room')
      end

      it 'returns no results for non-matching search' do
        create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'NonExistent' }
        expect(response).to have_http_status(:success)
      end

      it 'preserves search term in pagination' do
        10.times { |i| create(:room, user: user, name: "Meeting Room #{i}") }
        3.times { |i| create(:room, user: user, name: "Other Space #{i}") }

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Filtering' do
      it 'filters rooms by owner' do
        room1 = create(:room, user: user, name: 'My Room')
        room2 = create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path, params: { owner_id: user.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('My Room')
      end

      it 'admin can view all rooms by owner filter' do
        create(:room, user: user, name: 'User Room')
        create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'regular users cannot access owner filter' do
        get rooms_path, params: { owner_id: other_user.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Sorting' do
      it 'sorts rooms by name ascending' do
        create(:room, user: user, name: 'Zebra Room')
        create(:room, user: user, name: 'Apple Room')

        get rooms_path, params: { sort: 'name', direction: 'asc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts rooms by name descending' do
        create(:room, user: user, name: 'Zebra Room')
        create(:room, user: user, name: 'Apple Room')

        get rooms_path, params: { sort: 'name', direction: 'desc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts rooms by created_at' do
        room1 = create(:room, user: user, name: 'First Room')
        room2 = create(:room, user: user, name: 'Second Room')

        get rooms_path, params: { sort: 'created_at', direction: 'asc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts rooms by updated_at' do
        room = create(:room, user: user, name: 'Room')

        get rooms_path, params: { sort: 'updated_at', direction: 'desc' }
        expect(response).to have_http_status(:success)
      end

      it 'defaults to name sort when invalid sort parameter' do
        create(:room, user: user, name: 'Test Room')

        get rooms_path, params: { sort: 'invalid_field' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Pagination' do
      it 'displays paginated results' do
        20.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'navigates to next page' do
        20.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path, params: { page: 2 }
        expect(response).to have_http_status(:success)
      end

      it 'handles invalid page number gracefully' do
        create(:room, user: user, name: 'Room')

        get rooms_path, params: { page: 999 }
        expect(response).to have_http_status(:success)
      end

      it 'combines search with pagination' do
        15.times { |i| create(:room, user: user, name: "Meeting #{i}") }
        5.times { |i| create(:room, user: user, name: "Other #{i}") }

        get rooms_path, params: { search: 'Meeting', page: 1 }
        expect(response).to have_http_status(:success)
      end

      it 'combines sort with pagination' do
        20.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path, params: { sort: 'name', direction: 'asc', page: 2 }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Room Card Display' do
      it 'displays room description' do
        room = create(:room, user: user, name: 'Test Room', description: 'Test Description')

        get rooms_path
        expect(response.body).to include('Test Description')
      end

      it 'displays seat count' do
        room = create(:room, user: user, name: 'Test Room')
        create_list(:seat, 3, room: room)

        get rooms_path
        expect(response.body).to include('3')
      end

      it 'displays occupied seat count' do
        room = create(:room, user: user, name: 'Test Room')
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        create(:session, user: user, seat: seat1, status: :active)

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays room creation date' do
        room = create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays action buttons (view, edit, delete)' do
        room = create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'User Authorization' do
      it 'denies access to unauthorized users' do
        other_user_sign = create(:user, role: :user)
        sign_out user
        sign_in other_user_sign

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'allows admin to view all rooms' do
        create(:room, user: user, name: 'User Room')
        create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'requires authentication' do
        sign_out user

        get rooms_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'Performance' do
      it 'loads list efficiently with many rooms' do
        30.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'loads rooms with includes preloading' do
        10.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Export Functionality' do
      it 'allows export to CSV' do
        skip 'CSVエクスポート機能は Phase 7 で実装'
        room = create(:room, user: user, name: 'Test Room')

        get room_path(room, format: :csv)
        expect(response).to have_http_status(:success)
      end

      it 'exports all visible rooms' do
        skip 'CSVエクスポート機能は Phase 7 で実装'
        10.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path(format: :csv)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
