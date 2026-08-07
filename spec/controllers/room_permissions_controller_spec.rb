require "rails_helper"

RSpec.describe RoomPermissionsController, type: :controller do
  let(:room_owner) { create(:user, role: :manager) }
  let(:other_user) { create(:user) }
  let(:room) { create(:room, user: room_owner) }

  before do
    sign_in room_owner
  end

  describe "POST #create" do
    it "creates a new room permission" do
      expect do
        post :create, params: { room_id: room.id, room_permission: { user_id: other_user.id, permission_type: :edit } }
      end.to change(RoomPermission, :count).by(1)
    end

    it "redirects to room show on success" do
      post :create, params: { room_id: room.id, room_permission: { user_id: other_user.id, permission_type: :edit } }
      expect(response).to redirect_to(room_path(room))
    end

    it "denies non-room owner" do
      sign_out room_owner
      sign_in other_user
      expect do
        post :create, params: { room_id: room.id, room_permission: { user_id: other_user.id, permission_type: :edit } }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "DELETE #destroy" do
    let(:room_permission) { create(:room_permission, room:, user: other_user) }

    it "destroys the room permission" do
      room_permission
      expect do
        delete :destroy, params: { id: room_permission.id }
      end.to change(RoomPermission, :count).by(-1)
    end

    it "redirects to room show on success" do
      delete :destroy, params: { id: room_permission.id }
      expect(response).to redirect_to(room_path(room))
    end
  end
end
