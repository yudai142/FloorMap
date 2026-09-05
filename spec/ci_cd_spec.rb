require 'spec_helper'

RSpec.describe 'CI/CD Configuration', type: :feature do
  describe '.github/workflows/ci.yml' do
    let(:ci_config) { YAML.load_file('.github/workflows/ci.yml') }

    it 'has valid YAML syntax' do
      expect(ci_config).to be_a(Hash)
    end

    it 'defines required jobs' do
      jobs = ci_config['jobs'].keys
      expect(jobs).to include('scan_ruby', 'scan_js', 'lint', 'test', 'system-test')
    end

    it 'configures PostgreSQL service for test job' do
      test_job = ci_config['jobs']['test']
      postgres_service = test_job['services']['postgres']
      expect(postgres_service).to be_present
      expect(postgres_service['image']).to eq('postgres')
    end

    it 'sets DATABASE_URL for test job' do
      test_job = ci_config['jobs']['test']
      env_vars = test_job['steps'].find { |s| s['name'].include?('Run tests') }['env']
      expect(env_vars['DATABASE_URL']).to be_present
    end

    it 'runs RSpec tests' do
      test_job = ci_config['jobs']['test']
      run_tests_step = test_job['steps'].find { |s| s['name'] == 'Run tests' }
      expect(run_tests_step['run']).to include('rspec')
    end

    it 'runs security scans' do
      scan_ruby_job = ci_config['jobs']['scan_ruby']
      expect(scan_ruby_job['steps'].map { |s| s['name'] }).to include(
        include('Brakeman'),
        include('bundler-audit')
      )
    end
  end

  describe 'render.yaml' do
    let(:render_config) { YAML.load_file('render.yaml') }

    it 'has valid YAML syntax' do
      expect(render_config).to be_a(Hash)
    end

    it 'defines web service' do
      web_service = render_config['services'].find { |s| s['type'] == 'web' }
      expect(web_service).to be_present
      expect(web_service['name']).to eq('floormap-web')
    end

    it 'configures database service' do
      db_service = render_config['services'].find { |s| s['type'] == 'postgres' }
      expect(db_service).to be_present
      expect(db_service['name']).to eq('floormap-db')
    end

    it 'configures redis service' do
      redis_service = render_config['services'].find { |s| s['type'] == 'redis' }
      expect(redis_service).to be_present
      expect(redis_service['name']).to eq('floormap-redis')
    end

    it 'sets RAILS_ENV to production' do
      web_service = render_config['services'].find { |s| s['type'] == 'web' }
      rails_env = web_service['envVars'].find { |e| e['key'] == 'RAILS_ENV' }
      expect(rails_env['value']).to eq('production')
    end

    it 'includes database migration in build command' do
      web_service = render_config['services'].find { |s| s['type'] == 'web' }
      expect(web_service['buildCommand']).to include('rails db:migrate')
    end

    it 'includes npm ci in build command for Vite' do
      web_service = render_config['services'].find { |s| s['type'] == 'web' }
      expect(web_service['buildCommand']).to include('npm ci')
    end

    it 'configures RAILS_MASTER_KEY' do
      web_service = render_config['services'].find { |s| s['type'] == 'web' }
      master_key = web_service['envVars'].find { |e| e['key'] == 'RAILS_MASTER_KEY' }
      expect(master_key).to be_present
    end
  end

  describe 'Deployment readiness' do
    it 'has all required configuration files' do
      expect(File.exist?('.github/workflows/ci.yml')).to be true
      expect(File.exist?('render.yaml')).to be true
      expect(File.exist?('Gemfile')).to be true
      expect(File.exist?('package.json')).to be true
    end

    it 'has Ruby version specified' do
      expect(File.exist?('.ruby-version')).to be true
    end

    it 'has Node version specified' do
      expect(File.exist?('.nvmrc')).to be true
    end
  end
end
