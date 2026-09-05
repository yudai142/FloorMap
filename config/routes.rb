Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations"
  }

  resources :notifications, only: :index do
    collection do
      patch :mark_all_as_read
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Swagger UI for API documentation
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # ActionCable WebSocket
  mount ActionCable.server => "/cable"

  get "/" => "pages#home", as: :root

  resources :rooms, param: :share_token do
    resources :room_permissions, only: [ :create, :destroy ]
    resources :seats do
      member do
        patch :position
      end
      collection do
        patch :batch_position
        get :export
      end
    end
    member do
      get :canvas_editor
      get :canvas_data
      patch :floor_plan
    end
    collection do
      get :export
    end
  end

  resources :room_permissions, only: :destroy
  resources :sessions, only: [ :show, :index ] do
    collection do
      get :check_in_form
      post :check_in
      delete :check_out
      get :current_session
      get :history
    end
  end

  namespace :admin do
    resources :job_logs, only: [ :index, :show ]
  end

  resources :visitors, only: [ :edit, :update ] do
    collection do
      get :check_in
      post :check_in, action: :create_check_in
      delete :check_out
    end
  end
end
