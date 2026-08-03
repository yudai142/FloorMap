source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "~> 8.0.0"
gem "propshaft"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# Authentication & Authorization
gem "devise"
gem "devise-two-factor"
gem "pundit"

# Database
gem "rack-cors"

# Jobs
gem "good_job"

# Real-time
gem "redis"
gem "actioncable"

# API
gem "rswag"

# Observability
gem "sentry-rails"
gem "sentry-ruby"

# Audit
gem "paper_trail"

# Utils
gem "pagy"
gem "kaminari"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"
end
