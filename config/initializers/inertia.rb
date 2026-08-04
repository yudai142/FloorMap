InertiaRails.configure do |config|
  config.version = -> { File.mtime("#{Rails.root}/app/frontend").to_i }
  config.ssr_enabled = !Rails.env.development?
end
