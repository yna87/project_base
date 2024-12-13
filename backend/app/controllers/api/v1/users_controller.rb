module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]

      # GET /api/v1/users
      def index
        users = User.all
        render json: {
          status: 'success',
          data: users
        }
      end

      # GET /api/v1/users/:id
      def show
        render json: {
          status: 'success',
          data: @user
        }
      end

      # POST /api/v1/users
      def create
        user = Users.new(user_params)
        if user.save
          render json: {
            status: 'success',
            data: user
          }, status: :created
        else
          render json: {
            status: 'error',
            message: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: {
            status: 'success',
            data: @user
          }
        else
          render json: {
            status: 'error',
            message: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        render json: {
          status: 'success',
          message: 'Users was successfully deleted'
        }
      end

      private

      def set_user
        @user = Users.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: 'Users not found'
        }, status: :not_found
      end

      def user_params
        params.require(:user).permit(:name, :email)
      end
    end
  end
end










module Api
  module V1
    class UsersController < Sinatra::Base
      error SQLite3::Exception do
        status 500
        { error: env['sinatra.error'].message }.to_json
      end

      def show
  user = Users.find(params[:id])
  render json: {
    status: 'success',
    data: user
  }
end
    
      get '/users' do
        users = User.all
        users.to_json
      end
    
      get '/users/:id' do
        user = User.find(params[:id])
        halt 404, { error: 'User not found' }.to_json unless user
        user.to_json
      end
    
      post '/users' do
        data = JSON.parse(request.body.read, symbolize_names: true)
        user = User.create(data)
        status 201
        user.to_json
      end
    
      put '/users/:id' do
        data = JSON.parse(request.body.read, symbolize_names: true)
        user = User.find(params[:id])
        halt 404, { error: 'User not found' }.to_json unless user

        updated_user = User.update(params[:id], data)
        updated_user.to_json
      end
    
      delete '/users/:id' do
        user = User.find(params[:id])
        halt 404, { error: 'User not found' }.to_json unless user

        User.delete(params[:id])
        status 204
      end
    end
  end
end
