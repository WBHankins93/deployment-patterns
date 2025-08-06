#!/bin/bash
set -e

echo "🔄 Starting Rolling Deployment..."

BATCHES=("server-a" "server-b" "server-c")

for server in "${BATCHES[@]}"; do
  echo "🚀 Deploying to $server..."
  sleep 1
  echo "✅ $server updated successfully"
done

echo "🎉 Rolling Deployment Complete!"