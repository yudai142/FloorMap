Rswag::Ui.configure do |c|
  c.swagger_endpoint '/api-docs/swagger.json', name: 'FloorMap API v1'
end

Rswag::Api.configure do |c|
  c.swagger_root = Rails.root.to_s + '/swagger'

  c.swagger_docs = {
    'v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'FloorMap API',
        version: 'v1',
        description: 'FloorMap: Office seating management API'
      },
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development"
        },
        {
          url: "http://localhost:8000",
          description: "Testing"
        }
      ],
      paths: {},
      components: {
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              email: { type: :string },
              role: { type: :string, enum: ['user', 'manager', 'admin'] },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          },
          Room: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              user_id: { type: :integer },
              created_at: { type: :string, format: 'date-time' }
            }
          },
          Seat: {
            type: :object,
            properties: {
              id: { type: :integer },
              room_id: { type: :integer },
              row_number: { type: :integer },
              column_number: { type: :integer },
              seat_type: { type: :string, enum: ['regular', 'accessible', 'vip'] },
              position_x: { type: :number },
              position_y: { type: :number },
              created_at: { type: :string, format: 'date-time' }
            }
          },
          Session: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              visitor_id: { type: :integer },
              seat_id: { type: :integer },
              check_in_time: { type: :string, format: 'date-time' },
              check_out_time: { type: :string, format: 'date-time' },
              status: { type: :string, enum: ['active', 'completed', 'expired'] },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          }
        }
      }
    }
  }
end
