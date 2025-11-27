#!/bin/bash
set -euo pipefail

# Enhanced Rolling Deployment Script
#
# This script performs a Rolling deployment - gradually replacing instances
# of the application in batches, ensuring zero downtime.
#
# Usage:
#   ./scripts/rolling-batch-deploy.sh [version] [batch-size]
#
# Options:
#   version          - Version to deploy (default: "latest")
#   batch-size       - Number of servers to update per batch (default: 1)
#
# Environment Variables:
#   HEALTH_CHECK_URL        - Health check endpoint (default: http://localhost:8080/health)
#   HEALTH_CHECK_TIMEOUT    - Health check timeout in seconds (default: 10)
#   BATCH_DELAY             - Delay between batches in seconds (default: 30)
#   ROLLBACK_ON_FAILURE     - Auto-rollback on failure (default: true)
#
# Examples:
#   ./scripts/rolling-batch-deploy.sh v2.0.0 1
#   ./scripts/rolling-batch-deploy.sh v2.0.0 3
#   ROLLBACK_ON_FAILURE=false ./scripts/rolling-batch-deploy.sh v2.0.0 2

usage() {
    cat << EOF
Rolling Batch Deployment Script

Usage:
  ./scripts/rolling-batch-deploy.sh [version] [batch-size]

Arguments:
  version          Version to deploy (default: "latest")
  batch-size       Number of servers to update per batch (default: 1)

Environment Variables:
  HEALTH_CHECK_URL        Health check endpoint URL
                          (default: http://localhost:8080/health)
  HEALTH_CHECK_TIMEOUT    Health check timeout in seconds (default: 10)
  BATCH_DELAY             Delay between batches in seconds (default: 30)
  ROLLBACK_ON_FAILURE     Auto-rollback on failure: true|false (default: true)

Examples:
  ./scripts/rolling-batch-deploy.sh v2.0.0 1
  ./scripts/rolling-batch-deploy.sh v2.0.0 3
  ROLLBACK_ON_FAILURE=false ./scripts/rolling-batch-deploy.sh v2.0.0 2

For more information, see: patterns/rolling.md
EOF
    exit 1
}

# Parse arguments
VERSION=${1:-"latest"}
BATCH_SIZE=${2:-1}

# Show usage if help requested
if [ "$VERSION" = "-h" ] || [ "$VERSION" = "--help" ]; then
    usage
fi

HEALTH_CHECK_URL=${HEALTH_CHECK_URL:-"http://localhost:8080/health"}
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-10}
BATCH_DELAY=${BATCH_DELAY:-30}
MAX_HEALTH_RETRIES=5
ROLLBACK_ON_FAILURE=${ROLLBACK_ON_FAILURE:-true}

# Server configuration - in production, this would come from inventory/config
declare -a SERVERS=("server-a" "server-b" "server-c" "server-d" "server-e" "server-f")
TOTAL_SERVERS=${#SERVERS[@]}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# State tracking
declare -a DEPLOYED_SERVERS=()
declare -a FAILED_SERVERS=()
DEPLOYMENT_START_TIME=$(date +%s)

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
}

info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Function to check health of a specific server
check_server_health() {
    local server=$1
    local retries=0
    local health_url="${HEALTH_CHECK_URL/localhost/$server}"
    
    log "Checking health for $server..."
    
    while [ $retries -lt $MAX_HEALTH_RETRIES ]; do
        if timeout $HEALTH_CHECK_TIMEOUT curl -f -s "$health_url" > /dev/null 2>&1; then
            success "Health check passed for $server"
            return 0
        fi
        
        retries=$((retries + 1))
        warning "Health check failed for $server (attempt $retries/$MAX_HEALTH_RETRIES)"
        
        if [ $retries -lt $MAX_HEALTH_RETRIES ]; then
            sleep 5
        fi
    done
    
    error "Health checks failed for $server after $MAX_HEALTH_RETRIES attempts"
    return 1
}

# Function to deploy to a single server
deploy_to_server() {
    local server=$1
    
    log "🚀 Deploying version $VERSION to $server..."
    
    # Simulate deployment steps
    log "  → Stopping application on $server..."
    sleep 1
    
    log "  → Pulling new version ($VERSION) on $server..."
    sleep 1
    
    log "  → Starting application on $server..."
    sleep 2
    
    # Check if deployment was successful
    if check_server_health "$server"; then
        DEPLOYED_SERVERS+=("$server")
        success "$server updated successfully to version $VERSION"
        return 0
    else
        FAILED_SERVERS+=("$server")
        error "Deployment failed on $server"
        return 1
    fi
}

# Function to rollback a server
rollback_server() {
    local server=$1
    warning "🔄 Rolling back $server to previous version..."
    
    # Simulate rollback
    sleep 2
    
    if check_server_health "$server"; then
        success "Rollback successful for $server"
        # Remove from failed servers list
        FAILED_SERVERS=($(printf '%s\n' "${FAILED_SERVERS[@]}" | grep -v "^$server$"))
    else
        error "Rollback failed for $server - manual intervention required"
    fi
}

# Function to rollback all deployed servers
rollback_all() {
    warning "🔄 Rolling back all deployed servers..."
    
    for server in "${DEPLOYED_SERVERS[@]}"; do
        rollback_server "$server"
    done
    
    DEPLOYED_SERVERS=()
}

# Function to display deployment progress
show_progress() {
    local deployed_count=${#DEPLOYED_SERVERS[@]}
    local failed_count=${#FAILED_SERVERS[@]}
    local total_processed=$((deployed_count + failed_count))
    local progress_percent=$((total_processed * 100 / TOTAL_SERVERS))
    
    echo ""
    info "📊 Deployment Progress: $progress_percent% ($total_processed/$TOTAL_SERVERS servers)"
    info "✅ Successful: $deployed_count | ❌ Failed: $failed_count"
    
    if [ $deployed_count -gt 0 ]; then
        info "Deployed servers: ${DEPLOYED_SERVERS[*]}"
    fi
    
    if [ $failed_count -gt 0 ]; then
        warning "Failed servers: ${FAILED_SERVERS[*]}"
    fi
    echo ""
}

# Function to validate batch size
validate_batch_size() {
    # Check if batch size is a positive integer
    if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]]; then
        error "Invalid batch size: $BATCH_SIZE. Must be a positive integer"
        exit 1
    fi
    
    if [ $BATCH_SIZE -le 0 ] || [ $BATCH_SIZE -gt $TOTAL_SERVERS ]; then
        error "Invalid batch size: $BATCH_SIZE. Must be between 1 and $TOTAL_SERVERS"
        exit 1
    fi
    
    # Check if required tools are available
    local missing_tools=()
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    command -v timeout >/dev/null 2>&1 || missing_tools+=("timeout")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Required tools missing: ${missing_tools[*]}. Please install them and try again."
    fi
    
    # Validate health check URL format
    if [[ ! "$HEALTH_CHECK_URL" =~ ^https?:// ]]; then
        error "Invalid HEALTH_CHECK_URL format: $HEALTH_CHECK_URL (must start with http:// or https://)"
    fi
    
    info "Using batch size: $BATCH_SIZE"
    info "Total batches needed: $(((TOTAL_SERVERS + BATCH_SIZE - 1) / BATCH_SIZE))"
}

# Function to process a batch of servers
process_batch() {
    local batch_servers=("$@")
    local batch_success=true
    
    info "Processing batch: ${batch_servers[*]}"
    
    # Deploy to all servers in the batch in parallel
    for server in "${batch_servers[@]}"; do
        if ! deploy_to_server "$server"; then
            batch_success=false
        fi
    done
    
    return $batch_success
}

# Main rolling deployment function
rolling_deploy() {
    log "🔄 Starting Rolling Deployment..."
    log "Version: $VERSION | Batch Size: $BATCH_SIZE | Total Servers: $TOTAL_SERVERS"
    
    validate_batch_size
    
    # Process servers in batches
    local server_index=0
    local batch_number=1
    
    while [ $server_index -lt $TOTAL_SERVERS ]; do
        # Create current batch
        local batch_servers=()
        local batch_end=$((server_index + BATCH_SIZE))
        
        if [ $batch_end -gt $TOTAL_SERVERS ]; then
            batch_end=$TOTAL_SERVERS
        fi
        
        # Collect servers for this batch
        for ((i=server_index; i<batch_end; i++)); do
            batch_servers+=("${SERVERS[$i]}")
        done
        
        log "📦 Starting Batch $batch_number (servers: ${batch_servers[*]})"
        
        # Process the batch
        if process_batch "${batch_servers[@]}"; then
            success "Batch $batch_number completed successfully"
        else
            error "Batch $batch_number had failures"
            
            if [ "$ROLLBACK_ON_FAILURE" = true ]; then
                warning "Automatic rollback enabled - rolling back all changes"
                rollback_all
                exit 1
            else
                warning "Continuing deployment despite failures (ROLLBACK_ON_FAILURE=false)"
            fi
        fi
        
        show_progress
        
        # Wait before next batch (except for the last batch)
        server_index=$batch_end
        if [ $server_index -lt $TOTAL_SERVERS ]; then
            log "⏳ Waiting ${BATCH_DELAY}s before next batch..."
            sleep $BATCH_DELAY
        fi
        
        batch_number=$((batch_number + 1))
    done
}

# Function to display deployment summary
show_summary() {
    local deployment_end_time=$(date +%s)
    local total_time=$((deployment_end_time - DEPLOYMENT_START_TIME))
    local deployed_count=${#DEPLOYED_SERVERS[@]}
    local failed_count=${#FAILED_SERVERS[@]}
    
    echo ""
    echo "════════════════════════════════════════"
    log "📋 Rolling Deployment Summary"
    echo "════════════════════════════════════════"
    
    info "Version deployed: $VERSION"
    info "Batch size used: $BATCH_SIZE"
    info "Total deployment time: ${total_time}s"
    info "Servers successfully deployed: $deployed_count/$TOTAL_SERVERS"
    
    if [ $failed_count -eq 0 ]; then
        success "🎉 Rolling Deployment completed successfully!"
        success "All servers are now running version $VERSION"
    else
        warning "⚠️  Rolling Deployment completed with $failed_count failures"
        warning "Failed servers: ${FAILED_SERVERS[*]}"
        warning "Manual intervention may be required"
    fi
    
    echo ""
    info "📊 Next steps:"
    info "  • Monitor application metrics for anomalies"
    info "  • Check logs on all deployed servers"
    info "  • Verify end-to-end functionality"
    
    if [ $failed_count -gt 0 ]; then
        info "  • Investigate and retry failed servers"
        info "  • Consider running: $0 $VERSION 1  # Deploy to failed servers individually"
    fi
}

# Cleanup function for graceful shutdown
cleanup() {
    echo ""
    warning "🛑 Deployment interrupted!"
    
    if [ ${#DEPLOYED_SERVERS[@]} -gt 0 ]; then
        warning "Partially deployed servers: ${DEPLOYED_SERVERS[*]}"
        
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            warning "Rolling back deployed servers..."
            rollback_all
        else
            warning "Leaving partial deployment as-is (ROLLBACK_ON_FAILURE=false)"
        fi
    fi
    
    exit 1
}

# Main execution
main() {
    # Set up signal handlers
    trap cleanup INT TERM
    
    rolling_deploy
    show_summary
    
    # Exit with appropriate code
    if [ ${#FAILED_SERVERS[@]} -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function
main "$@"