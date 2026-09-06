if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = Rails.env
    config.traces_sample_rate = 0.1
    config.release = ENV["RENDER_GIT_COMMIT"] if ENV["RENDER_GIT_COMMIT"]

    # Ignore specific errors (use excluded_exceptions in sentry-ruby 6.x+)
    config.excluded_exceptions = config.excluded_exceptions + [
      "ActionController::RoutingError",
      "ActionController::UnknownAction",
      "AbstractController::ActionNotFound"
    ]
  end
end
