#!/bin/bash
set -euo pipefail

# Enhanced Big Bang Deployment Script
# 
# This script performs a Big Bang deployment - replacing all instances
# of the application with a new version simultaneously.
#
# Usage:
#   ./scripts/deploy.sh [version] [--rollback]
#
# Options:
#   version          - Version to deploy (default: "latest")
#   --rollback       - Rollback to previous version
#
# Environment Variables:
#   HEALTH_CHECK_URL - Health check endpoint (default: http://localhost:8080/health)
#
# Examples:
#   ./scripts/deploy.sh v2.0.0
#   ./scripts/deploy.sh v2.0.0 --rollback
#   HEALTH_CHECK_URL=https://api.example.com/health ./scripts/deploy.sh v2.0.0

usage() {
    cat << EOF
Big Bang Deployment Script

Usage:
  ./scripts/deploy.sh [version] [--rollback]

Arguments:
  version          Version to deploy (default: "latest")
  --rollback       Rollback to previous version

Environment Variables:
  HEALTH_CHECK_URL Health check endpoint URL
                   (default: http://localhost:8080/health)

Examples:
  ./scripts/deploy.sh v2.0.0
  ./scripts/deploy.sh v1.9.0 --rollback
  HEALTH_CHECK_URL=https://api.example.com/health ./scripts/deploy.sh v2.0.0

For more information, see: patterns/big-bang.md
EOF
    exit 1
}

# Parse arguments
VERSION=${1:-"latest"}
ROLLBACK_FLAG=${2:-""}

# Show usage if help requested
if [ "$VERSION" = "-h" ] || [ "$VERSION" = "--help" ]; then
    usage
fi

HEALTH_CHECK_URL=${HEALTH_CHECK_URL:-"http://localhost:8080/health"}
MAX_RETRIES=5
RETRY_DELAY=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Function to check service health
check_health() {
    local retries=0
    log "Checking service health..."
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            success "Health check passed"
            return 0
        fi
        
        retries=$((retries + 1))
        warning "Health check failed (attempt $retries/$MAX_RETRIES)"
        
        if [ $retries -lt $MAX_RETRIES ]; then
            log "Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done
    
    error "Health checks failed after $MAX_RETRIES attempts"
}

# Function to perform rollback
rollback() {
    log "🔄 Performing rollback..."
    
    # Get previous version
    PREVIOUS_VERSION=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "unknown")
    
    if [ "$PREVIOUS_VERSION" = "unknown" ]; then
        error "Cannot determine previous version for rollback"
    fi
    
    warning "Rolling back to version: $PREVIOUS_VERSION"
    
    # Simulate rollback deployment
    log "Stopping current services..."
    sleep 1
    
    log "Deploying previous version ($PREVIOUS_VERSION)..."
    sleep 2
    
    log "Starting services with previous version..."
    sleep 1
    
    check_health
    success "Rollback completed successfully!"
}

# Function to validate pre-deployment conditions
pre_deploy_validation() {
    log "🔍 Running pre-deployment validation..."
    
    # Check if required tools are available
    local missing_tools=()
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Required tools missing: ${missing_tools[*]}. Please install them and try again."
    fi
    
    # Validate version format (basic check)
    if [[ "$VERSION" != "latest" && ! "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-.*)?$ ]]; then
        warning "Version format may be invalid: $VERSION (expected: v1.2.3 or 1.2.3)"
    fi
    
    # Validate health check URL format
    if [[ ! "$HEALTH_CHECK_URL" =~ ^https?:// ]]; then
        error "Invalid HEALTH_CHECK_URL format: $HEALTH_CHECK_URL (must start with http:// or https://)"
    fi
    
    success "Pre-deployment validation passed"
}

# Function to run smoke tests
smoke_tests() {
    log "🧪 Running smoke tests..."
    
    # Basic connectivity test
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
        success "Connectivity test passed"
    else
        error "Connectivity test failed"
    fi
    
    # Additional smoke tests can be added here
    log "Checking core endpoints..."
    sleep 1
    
    success "All smoke tests passed"
}

# Main deployment function
deploy() {
    log "🚀 Starting Big Bang Deployment (Version: $VERSION)..."
    
    pre_deploy_validation
    
    # Store current version for potential rollback
    CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
    log "Current version: $CURRENT_VERSION"
    
    log "Pulling latest code..."
    # In production, this would be: git pull origin main
    sleep 1
    
    log "Building application (Version: $VERSION)..."
    # In production: docker build -t myapp:$VERSION .
    sleep 1
    
    log "Stopping all services..."
    # In production: docker-compose down or kubectl delete deployment myapp
    sleep 1
    
    log "Uploading to all servers..."
    # In production: docker push myapp:$VERSION
    sleep 1
    
    log "Starting services with new version..."
    # In production: docker-compose up -d or kubectl apply -f deployment.yaml
    sleep 1
    
    # Wait for services to start
    log "Waiting for services to initialize..."
    sleep 3
    
    check_health
    smoke_tests
    
    success "Big Bang Deployment complete!"
    log "🎉 Version $VERSION is now live on all servers"
}

# Main execution
main() {
    # Handle rollback flag
    if [ "$ROLLBACK_FLAG" = "--rollback" ]; then
        rollback
        exit 0
    fi
    
    # Trap to handle interruption
    trap 'error "Deployment interrupted! Consider running rollback."' INT TERM
    
    deploy
    
    log "📊 Post-deployment summary:"
    log "  - Deployed version: $VERSION"
    log "  - Deployment method: Big Bang"
    log "  - Health check URL: $HEALTH_CHECK_URL"
    log "  - Total deployment time: ~10 seconds (simulated)"
    
    warning "Monitor your application closely for the next few minutes"
    log "To rollback if needed, run: $0 $VERSION --rollback"
}

# Execute main function
main "$@"