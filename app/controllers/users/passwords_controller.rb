class Users::PasswordsController < Devise::PasswordsController
  before_action :configure_password_params, only: [:create, :update]

  protected

  def configure_password_params
    devise_parameter_sanitizer.permit(:password_reset, keys: [:email, :password, :password_confirmation, :reset_password_token])
  end
end
