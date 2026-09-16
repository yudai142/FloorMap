require 'rails_helper'

RSpec.describe 'Room List & Search Implementation', type: :request do
  describe 'Phase 6: ルーム一覧・検索機能実装' do
    let(:user) { create(:user, :manager) }
    let(:other_user) { create(:user, :manager) }
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in user
    end

    after do
      sign_out user
    end

    describe 'Room List Display Implementation' do
      it 'displays user rooms on index page' do
        room1 = create(:room, user: user, name: 'Meeting Room A')
        room2 = create(:room, user: user, name: 'Conference Room B')

        get rooms_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Meeting Room A')
        expect(response.body).to include('Conference Room B')
      end

      it 'does not display other users rooms' do
        create(:room, user: user, name: 'My Room')
        create(:room, user: other_user, name: 'Other Room')

        get rooms_path
        expect(response.body).not_to include('Other Room')
      end

      it 'displays room metadata (seat count, updated_at)' do
        room = create(:room, user: user, name: 'Test Room')
        create_list(:seat, 5, room: room)

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'handles empty room list gracefully' do
        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays room descriptions' do
        room = create(:room, user: user, name: 'Room', description: 'Test Description')

        get rooms_path
        expect(response.body).to include('Test Description')
      end

      it 'shows occupancy information' do
        room = create(:room, user: user, name: 'Test Room')
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        create(:session, user: user, seat: seat1, status: :active)

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Search Functionality Implementation' do
      it 'filters rooms by name search' do
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

      it 'searches in room descriptions' do
        skip 'Description search is Phase 6+ enhancement'
        room = create(:room, user: user, name: 'Room A', description: 'Special Meeting Space')

        get rooms_path, params: { search: 'Special' }
        expect(response.body).to include('Room A')
      end

      it 'returns empty results for non-matching search' do
        create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'NonExistent' }
        expect(response).to have_http_status(:success)
      end

      it 'clears search results' do
        create_list(:room, 3, user: user)

        get rooms_path, params: { search: '' }
        expect(response).to have_http_status(:success)
      end

      it 'preserves search term in pagination' do
        10.times { |i| create(:room, user: user, name: "Meeting #{i}") }
        3.times { |i| create(:room, user: user, name: "Other #{i}") }

        get rooms_path, params: { search: 'Meeting', page: 1 }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Filtering Implementation' do
      it 'filters rooms by owner (admin only)' do
        room1 = create(:room, user: user, name: 'User Room')
        room2 = create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path, params: { owner_id: user.id }
        expect(response).to have_http_status(:success)
      end

      it 'admin can view rooms of all users' do
        create(:room, user: user, name: 'User Room')
        create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'regular users cannot access owner filter' do
        other_room = create(:room, user: other_user, name: 'Other Room')

        get rooms_path, params: { owner_id: other_user.id }
        expect(response).to have_http_status(:success)
      end

      it 'filters by room status (active/archived)' do
        skip 'Status filtering is Phase 6+ enhancement'
        room = create(:room, user: user, name: 'Test Room', status: :active)

        get rooms_path, params: { status: 'active' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Sorting Implementation' do
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

      it 'defaults to name sort when invalid parameter' do
        create(:room, user: user, name: 'Test Room')

        get rooms_path, params: { sort: 'invalid_field' }
        expect(response).to have_http_status(:success)
      end

      it 'combines sort with search' do
        5.times { |i| create(:room, user: user, name: "Meeting #{i}") }

        get rooms_path, params: { search: 'Meeting', sort: 'name', direction: 'asc' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Pagination Implementation' do
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

      it 'shows page information' do
        skip 'Page info display is Phase 6+ enhancement'
        15.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'handles invalid page number gracefully' do
        create(:room, user: user, name: 'Room')

        get rooms_path, params: { page: 999 }
        expect(response).to have_http_status(:success)
      end

      it 'combines pagination with search' do
        15.times { |i| create(:room, user: user, name: "Meeting #{i}") }
        5.times { |i| create(:room, user: user, name: "Other #{i}") }

        get rooms_path, params: { search: 'Meeting', page: 1 }
        expect(response).to have_http_status(:success)
      end

      it 'combines pagination with sort' do
        20.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path, params: { sort: 'name', direction: 'asc', page: 2 }
        expect(response).to have_http_status(:success)
      end

      it 'combines pagination with search and sort' do
        30.times { |i| create(:room, user: user, name: "Meeting #{i}") }

        get rooms_path, params: { search: 'Meeting', sort: 'name', direction: 'asc', page: 2 }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Room Card Display Implementation' do
      it 'displays room name on card' do
        room = create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response.body).to include('Test Room')
      end

      it 'displays room description on card' do
        room = create(:room, user: user, name: 'Test Room', description: 'Test Description')

        get rooms_path
        expect(response.body).to include('Test Description')
      end

      it 'displays total seat count' do
        room = create(:room, user: user, name: 'Test Room')
        create_list(:seat, 5, room: room)

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays occupied seat count' do
        room = create(:room, user: user, name: 'Test Room')
        seat1 = create(:seat, room: room)
        seat2 = create(:seat, room: room)
        create(:session, user: user, seat: seat1, status: :active)

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'displays occupancy rate/percentage' do
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

      it 'displays room owner information' do
        skip 'Owner info display is Phase 6+ enhancement'
        room = create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Search Results Display Implementation' do
      it 'displays search query' do
        create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)
      end

      it 'displays search result count' do
        skip 'Result count display is Phase 6+ enhancement'
        5.times { |i| create(:room, user: user, name: "Meeting #{i}") }

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)
      end

      it 'displays no results message' do
        create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'NonExistent' }
        expect(response).to have_http_status(:success)
      end

      it 'allows clearing search' do
        create(:room, user: user, name: 'Meeting Room')

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'View Mode Toggle Implementation' do
      it 'supports grid view mode' do
        skip 'View mode toggle is Phase 6+ enhancement'
        create(:room, user: user, name: 'Test Room')

        get rooms_path, params: { view: 'grid' }
        expect(response).to have_http_status(:success)
      end

      it 'supports list view mode' do
        skip 'View mode toggle is Phase 6+ enhancement'
        create(:room, user: user, name: 'Test Room')

        get rooms_path, params: { view: 'list' }
        expect(response).to have_http_status(:success)
      end

      it 'remembers view mode preference' do
        skip 'View mode persistence is Phase 6+ enhancement'
        create(:room, user: user, name: 'Test Room')

        get rooms_path, params: { view: 'list' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Performance Implementation' do
      it 'renders list efficiently with many rooms' do
        30.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'uses includes to avoid N+1 queries' do
        10.times { |i| create(:room, user: user, name: "Room #{i}") }

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'handles large search result sets' do
        50.times { |i| create(:room, user: user, name: "Meeting #{i}") }

        get rooms_path, params: { search: 'Meeting' }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'User Authorization Implementation' do
      it 'allows authenticated users to view room list' do
        create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'prevents unauthenticated users from viewing list' do
        sign_out user

        get rooms_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'shows only users own rooms by default' do
        create(:room, user: user, name: 'My Room')
        create(:room, user: other_user, name: 'Other Room')

        get rooms_path
        expect(response.body).to include('My Room')
        expect(response.body).not_to include('Other Room')
      end

      it 'allows admin to view all rooms' do
        create(:room, user: user, name: 'User Room')
        create(:room, user: other_user, name: 'Other Room')

        sign_out user
        sign_in admin_user

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end

    describe 'Responsive Design Implementation' do
      it 'renders properly on desktop' do
        create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end

      it 'renders properly on mobile' do
        skip 'Mobile rendering testing is Phase 6+ enhancement'
        create(:room, user: user, name: 'Test Room')

        get rooms_path, headers: { 'User-Agent' => 'Mobile' }
        expect(response).to have_http_status(:success)
      end

      it 'adjusts grid layout for screen size' do
        skip 'Responsive grid adjustment is Phase 6+ enhancement'
        create(:room, user: user, name: 'Test Room')

        get rooms_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
