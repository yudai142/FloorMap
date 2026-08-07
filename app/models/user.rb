class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         :two_factor_authenticatable
end
