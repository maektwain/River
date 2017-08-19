Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  #users

  match api_path + '/videos',     to: 'videos#index', via: :get
  match api_path + '/videos',     to: 'videos#create', via: :post


end