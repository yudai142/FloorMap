Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  get "/" => "pages#home", as: :root

  resources :rooms do
    resources :room_permissions, only: [ :create, :destroy ]
    resources :seats
  end

  resources :room_permissions, only: :destroy
end
