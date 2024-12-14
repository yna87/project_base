module Api
  module V1
    class {{ table.plural_name | pascalcase }}Controller < ApplicationController
      before_action :set_{{ table.name | lower }}, only: [:show, :update, :destroy]

      # GET /api/v1/{{ table.plural_name | lower }}
      def index
        {{ table.plural_name | lower }} = {{ table.name | pascalcase }}.all
        render json: {
          status: 'success',
          items: {{ table.plural_name | lower }},
          count: {{ table.plural_name | lower }}.count
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
        {{ table.name | lower }} = {{ table.name | pascalcase }}.new({{ table.name | lower }}_params)
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
          message: '{{ table.name | pascalcase }} was successfully deleted'
        }
      end

      private

      def set_{{ table.name | lower }}
        @{{ table.name | lower }} = {{ table.plural_name | pascalcase }}.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: '{{ table.name | pascalcase }} not found'
        }, status: :not_found
      end

      def {{ table.name | lower }}_params
        params.require(:{{ table.name | lower }}).permit(:name, :email)
      end
    end
  end
end

