Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :geolocations, only: %i[index show create destroy], param: :ip_address,
                               constraints: { ip_address: /[^\/]+/ }
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
