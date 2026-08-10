require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'devise integration' do
    it 'includes database_authenticatable' do
      expect(User.new.respond_to?(:encrypted_password)).to be true
    end

    it 'includes registerable' do
      expect(User).to respond_to(:devise_modules)
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes two_factor_authenticatable' do
      expect(User.devise_modules).to include(:two_factor_authenticatable)
    end

    it 'is an active record model' do
      expect(User.superclass).to eq(ApplicationRecord)
    end
  end

  describe 'validation' do
    it 'is invalid without an email' do
      user = User.new(email: nil, password: 'password', password_confirmation: 'password')
      expect(user).not_to be_valid
    end

    it 'is invalid with a duplicate email' do
      create(:user, email: 'test@example.com')
      user = User.new(email: 'test@example.com', password: 'password', password_confirmation: 'password')
      expect(user).not_to be_valid
    end

    it 'is invalid without a password' do
      user = User.new(email: 'test@example.com', password: nil)
      expect(user).not_to be_valid
    end
  end

  describe 'creation' do
    it 'creates a valid user with email and password' do
      user = create(:user, email: 'newuser@example.com')
      expect(user.persisted?).to be true
      expect(user.email).to eq('newuser@example.com')
    end

    it 'generates a unique email sequence' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end

  describe 'password encryption' do
    it 'encrypts the password' do
      user = create(:user)
      expect(user.encrypted_password).not_to be_blank
      expect(user.encrypted_password).not_to eq('password123')
    end
  end

  describe 'roles' do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, manager: 1, admin: 2) }

    it 'defaults to user role' do
      user = create(:user)
      expect(user.role).to eq('user')
      expect(user.user?).to be true
    end

    it 'can be set to manager role' do
      user = create(:user, role: :manager)
      expect(user.role).to eq('manager')
      expect(user.manager?).to be true
      expect(user.user?).to be false
    end

    it 'can be set to admin role' do
      user = create(:user, role: :admin)
      expect(user.role).to eq('admin')
      expect(user.admin?).to be true
      expect(user.user?).to be false
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:room_permissions) }
    it { is_expected.to have_many(:rooms).dependent(:destroy) }
  end

  describe '#owner_of?' do
    let(:manager) { create(:user, :manager) }
    let(:other_user) { create(:user) }
    let(:room) { create(:room, user: manager) }

    it 'returns true when user is the owner' do
      expect(manager.owner_of?(room)).to be true
    end

    it 'returns false when user is not the owner' do
      expect(other_user.owner_of?(room)).to be false
    end
  end

  describe '#has_permission_in?' do
    let(:manager) { create(:user, :manager) }
    let(:other_user) { create(:user) }
    let(:room) { create(:room, user: manager) }

    context 'when user has permission' do
      before { create(:room_permission, room: room, user: other_user) }

      it 'returns true' do
        expect(other_user.has_permission_in?(room)).to be true
      end
    end

    context 'when user does not have permission' do
      it 'returns false' do
        expect(other_user.has_permission_in?(room)).to be false
      end
    end
  end
end
