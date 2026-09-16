require 'rails_helper'

RSpec.describe 'API Documentation', type: :request do
  describe 'Issue #69: API ドキュメント（Swagger/rswag）' do
    describe 'Swagger Configuration' do
      it 'Swagger/rswag gem is available' do
        expect(defined?(Rswag)).to be_truthy
      end

      it 'rswag configuration is loaded' do
        expect(defined?(Rswag::Api)).to be_truthy
      end

      pending 'GET /api-docs displays Swagger UI' do
        get '/api-docs'
        expect(response).to have_http_status(:ok)
      end

      pending 'GET /api-docs/swagger.json returns OpenAPI spec' do
        get '/api-docs/swagger.json'
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('json')
      end
    end

    describe 'OpenAPI Schemas' do
      pending 'User schema is defined' do
        expect(Rswag::Api.config.swagger_docs['v1/swagger.json'][:components][:schemas][:User]).to be_present
      end

      pending 'Room schema is defined' do
        expect(Rswag::Api.config.swagger_docs['v1/swagger.json'][:components][:schemas][:Room]).to be_present
      end

      pending 'Seat schema is defined' do
        expect(Rswag::Api.config.swagger_docs['v1/swagger.json'][:components][:schemas][:Seat]).to be_present
      end

      pending 'Session schema is defined' do
        expect(Rswag::Api.config.swagger_docs['v1/swagger.json'][:components][:schemas][:Session]).to be_present
      end
    end
  end
end
