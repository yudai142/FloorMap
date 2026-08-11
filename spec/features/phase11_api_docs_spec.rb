require 'rails_helper'

RSpec.describe 'API Documentation', type: :request do
  describe 'Issue #69: API ドキュメント（Swagger/rswag）' do
    describe 'Swagger UI' do
      pending 'GET /api-docs displays Swagger UI' do
        get '/api-docs'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Swagger UI')
      end

      pending 'Swagger specification is valid JSON' do
        get '/api/swagger.json'
        expect(response).to have_http_status(:ok)
        expect { JSON.parse(response.body) }.not_to raise_error
      end
    end

    describe 'API Endpoints Documentation' do
      pending 'GET /api/v1/rooms endpoint is documented' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        expect(spec['paths']['/api/v1/rooms']['get']).to be_present
      end

      pending 'GET /api/v1/rooms/:id/seats endpoint is documented' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        expect(spec['paths']['/api/v1/rooms/{id}/seats']['get']).to be_present
      end

      pending 'POST /api/v1/sessions/check_in endpoint is documented' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        expect(spec['paths']['/api/v1/sessions/check_in']['post']).to be_present
      end

      pending 'API documentation includes request/response schemas' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        expect(spec['components']['schemas']).to be_present
      end
    end

    describe 'Documentation Accuracy' do
      pending 'Documented endpoint parameters match actual implementation' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        room_schema = spec['components']['schemas']['Room']
        expect(room_schema['properties']).to include('id', 'name', 'capacity')
      end

      pending 'Response examples in documentation are accurate' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        expect(spec['paths']).to include('/api/v1/rooms')
      end

      pending 'Error responses are documented' do
        get '/api/swagger.json'
        spec = JSON.parse(response.body)
        room_get = spec['paths']['/api/v1/rooms/{id}']['get']
        expect(room_get['responses']).to include('404', '401')
      end
    end
  end
end
