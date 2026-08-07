require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #home' do
    it 'returns a 200 status' do
      get :home
      expect(response).to have_http_status(:success)
    end

    it 'routes to home action' do
      expect(get: '/').to route_to(controller: 'pages', action: 'home')
    end

    context 'when user is not authenticated' do
      it 'has no current user' do
        get :home
        expect(controller.current_user).to be nil
      end
    end

    context 'when user is authenticated' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'sets current user' do
        get :home
        expect(controller.current_user).to eq(user)
      end

      it 'current_user has correct email' do
        get :home
        expect(controller.current_user.email).to eq(user.email)
      end
    end
  end
end
