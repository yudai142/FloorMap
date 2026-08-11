if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  # Raise errors in test environment
  if Rails.env.test?
    Bullet.raise = true
  end

  # Whitelist N+1 queries that are acceptable (optional)
  # Bullet.add_whitelist(type: :n_plus_one_query, class_name: 'Room', association: :seats)
end
