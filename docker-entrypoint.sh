#!/bin/bash
set -e

# Remove stale PID file
rm -f /app/tmp/pids/server.pid

# Prepare database
bundle exec rails db:prepare

# Start server
exec bundle exec rails server -b 0.0.0.0
