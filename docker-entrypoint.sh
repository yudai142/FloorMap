#!/bin/bash
set -e

# Remove stale PID file
rm -f /app/tmp/pids/server.pid

# Clean Vite cache for development
rm -rf /app/public/vite /app/.vite /app/node_modules/.vite

# Prepare database
bundle exec rails db:prepare

# Build Vite once for initial load
echo "Building Vite..."
bundle exec vite build

# Start Rails server (which will auto-build Vite on file changes)
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0
