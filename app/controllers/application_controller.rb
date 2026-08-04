class ApplicationController < ActionController::Base
  include InertiaRails::Controller

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def default_inertia_props
    {
      auth: {
        user: current_user&.slice(:id, :email, :name),
        is_authenticated: user_signed_in?,
      },
    }
  end
end
