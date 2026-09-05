#!/bin/bash
set -e

# Remove stale PID file
rm -f /app/tmp/pids/server.pid

# Clean Vite cache for development
rm -rf /app/public/vite /app/.vite /app/node_modules/.vite

# Prepare database
bundle exec rails db:prepare

# Start Rails server
exec bundle exec rails server -b 0.0.0.0
