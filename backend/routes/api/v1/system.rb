module Api
  module V1
    class SystemController < Sinatra::Base
      before do
        content_type :json
      end

      get '/health_check' do
        {
          status: 'ok',
          message: 'Backend is running!',
          timestamp: Time.now,
          database: database_status
        }.to_json
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
