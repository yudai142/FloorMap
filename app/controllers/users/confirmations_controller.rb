class Users::ConfirmationsController < Devise::ConfirmationsController
  before_action :configure_confirmation_params, only: [:create]

  protected

  def configure_confirmation_params
    devise_parameter_sanitizer.permit(:confirmation, keys: [:email])
  end
end
