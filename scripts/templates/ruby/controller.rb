module Api
  module V1
    class {{ table.plural_name | pascalcase }}Controller < ApplicationController
      before_action :set_{{ table.name | lower }}, only: [:show, :update, :destroy]

      # GET /api/v1/{{ table.plural_name | lower }}
      def index
        {{ table.plural_name | lower }} = {{ table.name | pascalcase }}.all
        render json: {
          status: 'success',
          data: {{ table.plural_name | lower }}
        }
      end

      # GET /api/v1/{{ table.plural_name | lower }}/:id
      def show
        render json: {
          status: 'success',
          data: @{{ table.name | lower }}
        }
      end

      # POST /api/v1/{{ table.plural_name | lower }}
      def create
        {{ table.name | lower }} = {{ table.plural_name | pascalcase }}.new({{ table.name | lower }}_params)
        if {{ table.name | lower }}.save
          render json: {
            status: 'success',
            data: {{ table.name | lower }}
          }, status: :created
        else
          render json: {
            status: 'error',
            message: {{ table.name | lower }}.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/{{ table.plural_name | lower }}/:id
      def update
        if @{{ table.name | lower }}.update({{ table.name | lower }}_params)
          render json: {
            status: 'success',
            data: @{{ table.name | lower }}
          }
        else
          render json: {
            status: 'error',
            message: @{{ table.name | lower }}.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/{{ table.plural_name | lower }}/:id
      def destroy
        @{{ table.name | lower }}.destroy
        render json: {
          status: 'success',
          message: '{{ table.plural_name | pascalcase }} was successfully deleted'
        }
      end

      private

      def set_{{ table.name | lower }}
        @{{ table.name | lower }} = {{ table.plural_name | pascalcase }}.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: '{{ table.plural_name | pascalcase }} not found'
        }, status: :not_found
      end

      def {{ table.name | lower }}_params
        params.require(:{{ table.name | lower }}).permit(:name, :email)
      end
    end
  end
end










module Api
  module V1
    class {{ table.plural_name | pascalcase }}Controller < Sinatra::Base
      error SQLite3::Exception do
        status 500
        { error: env['sinatra.error'].message }.to_json
      end

      def show
  {{ table.name | lower }} = {{ table.plural_name | pascalcase }}.find(params[:id])
  render json: {
    status: 'success',
    data: {{ table.name | lower }}
  }
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

