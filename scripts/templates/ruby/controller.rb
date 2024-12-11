module Api
  module V1
    class {{ table.plural_name | pascalcase }}Controller < Sinatra::Base
      require './models/{{ table.name | lower }}'

      before do
        content_type :json
      end
    
      error SQLite3::Exception do
        status 500
        { error: env['sinatra.error'].message }.to_json
      end
    
      get '/{{ table.plural_name | lower }}' do
        {{ table.plural_name | lower }} = {{ table.name }}.all
        {{ table.plural_name | lower }}.to_json
      end
    
      get '/{{ table.plural_name | lower }}/:id' do
        {{ table.name | lower }} = {{ table.name }}.find(params[:id])
        halt 404, { error: '{{ table.name }} not found' }.to_json unless {{ table.name | lower }}
        {{ table.name | lower }}.to_json
      end
    
      post '/{{ table.plural_name | lower }}' do
        data = JSON.parse(request.body.read, symbolize_names: true)
        {{ table.name | lower }} = {{ table.name }}.create(data)
        status 201
        {{ table.name | lower }}.to_json
      end
    
      put '/{{ table.plural_name | lower }}/:id' do
        data = JSON.parse(request.body.read, symbolize_names: true)
        {{ table.name | lower }} = {{ table.name }}.find(params[:id])
        halt 404, { error: '{{ table.name }} not found' }.to_json unless {{ table.name | lower }}

        updated_{{ table.name | lower }} = {{ table.name }}.update(params[:id], data)
        updated_{{ table.name | lower }}.to_json
      end
    
      delete '/{{ table.plural_name | lower }}/:id' do
        {{ table.name | lower }} = {{ table.name }}.find(params[:id])
        halt 404, { error: '{{ table.name }} not found' }.to_json unless {{ table.name | lower }}

        {{ table.name }}.delete(params[:id])
        status 204
      end
    end
  end
end
