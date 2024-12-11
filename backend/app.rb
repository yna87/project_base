require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require 'rack/cors'

set :database_file, 'config/database.yml'

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
