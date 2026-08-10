require "rails_helper"

RSpec.describe RoomPermissionsController, type: :controller do
  let(:room_owner) { create(:user, role: :manager) }
  let(:other_user) { create(:user) }
  let(:admin_user) { create(:user, role: :admin) }
  let(:room) { create(:room, user: room_owner) }

  describe "POST #create" do
    context "when user is room owner" do
      before { sign_in room_owner }

      it "creates a new room permission with view type" do
        expect do
          post :create, params: {
            room_id: room.id,
            room_permission: { user_id: other_user.id, permission_type: :view }
          }
        end.to change(RoomPermission, :count).by(1)

        expect(RoomPermission.last.permission_type).to eq("view")
      end

      it "creates a new room permission with edit type" do
        expect do
          post :create, params: {
            room_id: room.id,
            room_permission: { user_id: other_user.id, permission_type: :edit }
          }
        end.to change(RoomPermission, :count).by(1)

        expect(RoomPermission.last.permission_type).to eq("edit")
      end

      it "creates a new room permission with manage type" do
        expect do
          post :create, params: {
            room_id: room.id,
            room_permission: { user_id: other_user.id, permission_type: :manage }
          }
        end.to change(RoomPermission, :count).by(1)

        expect(RoomPermission.last.permission_type).to eq("manage")
      end

      it "redirects to room show on success" do
        post :create, params: {
          room_id: room.id,
          room_permission: { user_id: other_user.id, permission_type: :edit }
        }
        expect(response).to redirect_to(room_path(room))
      end

      it "returns flash success message" do
        post :create, params: {
          room_id: room.id,
          room_permission: { user_id: other_user.id, permission_type: :edit }
        }
        expect(flash[:notice]).to include("権限を付与しました")
      end
    end

    context "when user is not room owner" do
      before { sign_in other_user }

      it "denies non-room owner from creating permissions" do
        post :create, params: {
          room_id: room.id,
          room_permission: { user_id: other_user.id, permission_type: :edit }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "allows admin to create permissions" do
        expect do
          post :create, params: {
            room_id: room.id,
            room_permission: { user_id: other_user.id, permission_type: :edit }
          }
        end.to change(RoomPermission, :count).by(1)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:room_permission) { create(:room_permission, room:, user: other_user) }

    context "when user is room owner" do
      before { sign_in room_owner }

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

      it "returns flash success message" do
        delete :destroy, params: { id: room_permission.id }
        expect(flash[:notice]).to include("権限を削除しました")
      end
    end

    context "when user is not room owner" do
      before { sign_in other_user }

      it "denies non-room owner from destroying permissions" do
        delete :destroy, params: { id: room_permission.id }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "allows admin to destroy permissions" do
        room_permission
        expect do
          delete :destroy, params: { id: room_permission.id }
        end.to change(RoomPermission, :count).by(-1)
      end
    end
  end
end
