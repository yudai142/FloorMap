class ApplicationController < ActionController::Base
  include InertiaRails::Controller
  include Pundit::Authorization

  allow_browser versions: :modern

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def default_inertia_props
    {
      auth: {
        user: current_user ? {
          id: current_user.id,
          email: current_user.email,
          username: current_user.username,
          name: current_user.name
        } : nil,
        is_authenticated: user_signed_in?
      }
    }
  end

  private

  def user_not_authorized
    redirect_to root_path, alert: "You are not authorized to perform this action."
  end
end
