Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "polls#index"

  resources :polls, param: :slug do
    member do
      post :open
      post :close
    end
    resources :votes, only: [:create]
  end
end
