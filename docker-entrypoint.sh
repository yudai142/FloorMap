#!/bin/bash
set -e

# Remove stale PID file
rm -f /app/tmp/pids/server.pid

# Clean Vite cache for development
rm -rf /app/public/vite /app/.vite /app/node_modules/.vite

# Prepare database
bundle exec rails db:prepare

# Start Vite dev server in background with logging
echo "Starting Vite dev server..."
npm run dev > /tmp/vite.log 2>&1 &
VITE_PID=$!
echo "Vite PID: $VITE_PID"

# Wait for Vite to start
sleep 10

# Show Vite logs
echo "=== Vite startup logs ==="
cat /tmp/vite.log || echo "No Vite logs yet"

# Start Rails server
echo "Starting Rails server..."
bundle exec rails server -b 0.0.0.0 &
RAILS_PID=$!

# Handle shutdown gracefully
trap "kill $VITE_PID $RAILS_PID 2>/dev/null || true" EXIT

# Wait for both processes
wait $VITE_PID $RAILS_PID
