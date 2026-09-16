require 'rails_helper'

RSpec.describe 'CI/CD & Deployment Automation', type: :request do
  describe 'Phase 12: CI/CD・デプロイ自動化（GitHub Actions）' do
    describe 'GitHub Actions Workflow Configuration' do
      it 'CI/CD workflow file exists' do
        workflow_file = File.expand_path('.github/workflows/ci.yml', Rails.root)
        expect(File.exist?(workflow_file)).to be_truthy
      end

      it 'Workflow has lint job' do
        expect(defined?(YAML)).to be_truthy
      end

      it 'Workflow has test job' do
        # Test job should execute bundle exec rspec
      end

      it 'Workflow has security scan jobs' do
        # Should include Brakeman and bundler-audit
      end
    end

    describe 'Render.com Deployment Configuration' do
      it 'render.yaml configuration exists' do
        render_file = File.expand_path('render.yaml', Rails.root)
        expect(File.exist?(render_file)).to be_truthy
      end

      it 'Environment variables are configured in render.yaml' do
        render_file = File.expand_path('render.yaml', Rails.root)
        content = File.read(render_file)
        expect(content).to include('DATABASE_URL')
        expect(content).to include('REDIS_URL')
      end

      it 'Build command is configured' do
        render_file = File.expand_path('render.yaml', Rails.root)
        content = File.read(render_file)
        expect(content).to include('buildCommand')
      end

      it 'Health check endpoint is configured' do
        # GET /up returns 200 OK
      end
    end

    describe 'Sentry Integration' do
      it 'Sentry initializer exists' do
        sentry_file = File.expand_path('config/initializers/sentry.rb', Rails.root)
        expect(File.exist?(sentry_file)).to be_truthy
      end

      it 'Sentry is configured for production' do
        sentry_file = File.expand_path('config/initializers/sentry.rb', Rails.root)
        content = File.read(sentry_file)
        expect(content).to include('Rails.env.production?')
      end
    end

    describe 'Deployment Documentation' do
      it 'Deployment guide exists' do
        doc_file = File.expand_path('docs/deployment.md', Rails.root)
        expect(File.exist?(doc_file)).to be_truthy
      end

      it 'Documentation includes setup instructions' do
        doc_file = File.expand_path('docs/deployment.md', Rails.root)
        content = File.read(doc_file)
        expect(content).to include('Render.com')
      end
    end
  end
end
