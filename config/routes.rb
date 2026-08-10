Rails.application.routes.draw do
  devise_for :users

  resources :notifications, only: :index do
    collection do
      patch :mark_all_as_read
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  get "/" => "pages#home", as: :root

  resources :rooms do
    resources :room_permissions, only: [ :create, :destroy ]
    resources :seats do
      member do
        patch :position
      end
      collection do
        patch :batch_position
      end
    end
    get :canvas_data
  end

  resources :room_permissions, only: :destroy
  resources :sessions, only: [ :show ] do
    collection do
      post :check_in
      delete :check_out
      get :current_session
      get :history
    end
  end
end
