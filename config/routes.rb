Rails.application.routes.draw do
  root 'sessions#new'
  get '/sessions/new', to: 'sessions#new'
  get '/sessions/auth', to: 'sessions#auth'
end
