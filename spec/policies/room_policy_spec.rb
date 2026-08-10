require 'rails_helper'

RSpec.describe RoomPolicy, type: :policy do
  let(:admin_user) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:regular_user) { create(:user, :user) }
  let(:room) { create(:room, user: manager) }

  subject { RoomPolicy.new(user, room) }

  describe '#show?' do
    context 'when user is the owner' do
      let(:user) { manager }
      it { is_expected.to permit(:show) }
    end

    context 'when user has permission in the room' do
      let(:user) { regular_user }

      before { create(:room_permission, room: room, user: user) }

      it { is_expected.to permit(:show) }
    end

    context 'when user has no permission' do
      let(:user) { regular_user }
      it { is_expected.not_to permit(:show) }
    end
  end

  describe '#create?' do
    context 'when user is a manager' do
      let(:user) { manager }
      it { is_expected.to permit(:create) }
    end

    context 'when user is an admin' do
      let(:user) { admin_user }
      it { is_expected.to permit(:create) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }
      it { is_expected.not_to permit(:create) }
    end
  end

  describe '#update?' do
    context 'when user is the owner' do
      let(:user) { manager }
      it { is_expected.to permit(:update) }
    end

    context 'when user is not the owner' do
      let(:user) { regular_user }
      it { is_expected.not_to permit(:update) }
    end
  end

  describe '#destroy?' do
    context 'when user is the owner' do
      let(:user) { manager }
      it { is_expected.to permit(:destroy) }
    end

    context 'when user is not the owner' do
      let(:user) { regular_user }
      it { is_expected.not_to permit(:destroy) }
    end
  end
end
