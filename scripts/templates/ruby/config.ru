require './app'
require './routes/api/v1/system'
{% for table in tables %}
require './routes/api/v1/{{ table.plural_name | lower }}'
{% endfor %}

use Rack::Cors do
  allow do
    origins 'http://localhost:5173'
    resource '*', 
      methods: [:get, :post, :put, :delete, :options],
      headers: :any,
      credentials: true,
      max_age: 600
  end
end

map('/api/v1') do
  use Api::V1::SystemController
  {% for table in tables %}
  use Api::V1::{{ table.plural_name | pascalcase }}Controller
  {% endfor %}
end

run Sinatra::Application
