module Api
  module V1
    class HealthController < ApplicationController
      def check
        render json: {
          status: 'ok',
          message: 'Backend is running!',
          timestamp: Time.current,
          database: database_status
        }
      end

      private

      def database_status
        ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
      rescue StandardError
        'error'
      end
    end
  end
end
