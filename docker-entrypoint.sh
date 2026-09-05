#!/bin/bash
set -e

# Remove stale PID file
rm -f /app/tmp/pids/server.pid

# Clean Vite cache for development
rm -rf /app/public/vite /app/.vite /app/node_modules/.vite

# Prepare database
bundle exec rails db:prepare

# Start Vite file watcher in background
echo "Starting Vite file watcher..."
npm run watch > /tmp/vite-watch.log 2>&1 &
VITE_PID=$!

# Wait for initial build to complete
sleep 5

# Start Rails server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0
