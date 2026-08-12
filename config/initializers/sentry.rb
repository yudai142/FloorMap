if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = Rails.env
    config.traces_sample_rate = 0.1
    config.release = ENV["RENDER_GIT_COMMIT"] if ENV["RENDER_GIT_COMMIT"]

    # Ignore specific errors
    config.ignored_errors = [
      "ActionController::RoutingError",
      "ActionController::UnknownAction",
      "AbstractController::ActionNotFound"
    ]

    # Performance monitoring
    config.enable_tracing = true
  end
end
