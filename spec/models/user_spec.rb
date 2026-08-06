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
end
