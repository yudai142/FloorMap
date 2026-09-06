class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    return redirect_to rooms_path if user_signed_in?
    render inertia: "Home"
  end
end
