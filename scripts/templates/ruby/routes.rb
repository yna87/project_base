Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        get 'health_check', to: 'health#check'
        {% for table in tables %}
        resources :{{ table.plural_name | lower }}
        {% endfor %}
      end
    end
  end

