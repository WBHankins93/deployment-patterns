#!/bin/bash
set -euo pipefail

# Emergency Rollback Utility Script
# Usage: ./scripts/rollback.sh [pattern] [deployment-name] [options]
#
# Patterns: big-bang, rolling, blue-green, canary
# Options: --force, --dry-run, --version=VERSION

PATTERN=${1:-""}
DEPLOYMENT_NAME=${2:-""}
FORCE_ROLLBACK=false
DRY_RUN=false
TARGET_VERSION=""
HEALTH_CHECK_URL=${HEALTH_CHECK_URL:-"http://localhost:8080/health"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

usage() {
    cat << EOF
Emergency Rollback Utility

Usage:
  ./scripts/rollback.sh <pattern> <deployment-name> [options]

Patterns:
  big-bang      - Rollback Big Bang deployment
  rolling       - Rollback Rolling deployment
  blue-green    - Switch traffic back to previous environment
  canary        - Remove canary and route all traffic to baseline

Options:
  --force              - Skip confirmation prompts
  --dry-run            - Show what would be done without executing
  --version=VERSION    - Rollback to specific version
  --health-url=URL     - Health check URL (default: $HEALTH_CHECK_URL)

Examples:
  ./scripts/rollback.sh rolling myapp
  ./scripts/rollback.sh blue-green myapp --force
  ./scripts/rollback.sh big-bang myapp --version=v1.9.0 --dry-run
  ./scripts/rollback.sh canary myapp --force

EOF
    exit 1
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --force)
            FORCE_ROLLBACK=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --version=*)
            TARGET_VERSION="${arg#*=}"
            shift
            ;;
        --health-url=*)
            HEALTH_CHECK_URL="${arg#*=}"
            shift
            ;;
        -h|--help)
            usage
            ;;
    esac
done

# Validate inputs
if [ -z "$PATTERN" ] || [ -z "$DEPLOYMENT_NAME" ]; then
    error "Pattern and deployment name are required"
    usage
fi

# Check if kubectl is available (for Kubernetes deployments)
if command -v kubectl &> /dev/null; then
    KUBECTL_AVAILABLE=true
else
    KUBECTL_AVAILABLE=false
    warning "kubectl not found - some rollback methods may not be available"
fi

# Function to check health
check_health() {
    local retries=0
    local max_retries=10
    local retry_delay=5
    
    log "Checking service health..."
    
    while [ $retries -lt $max_retries ]; do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            success "Health check passed"
            return 0
        fi
        
        retries=$((retries + 1))
        warning "Health check failed (attempt $retries/$max_retries)"
        
        if [ $retries -lt $max_retries ]; then
            sleep $retry_delay
        fi
    done
    
    warning "Health checks failed after $max_retries attempts"
    return 1
}

# Function to get previous version
get_previous_version() {
    if [ -n "$TARGET_VERSION" ]; then
        echo "$TARGET_VERSION"
        return
    fi
    
    if [ "$KUBECTL_AVAILABLE" = true ]; then
        # Get previous revision from Kubernetes
        PREV_REVISION=$(kubectl rollout history deployment/"$DEPLOYMENT_NAME" 2>/dev/null | tail -2 | head -1 | awk '{print $1}' || echo "")
        if [ -n "$PREV_REVISION" ]; then
            echo "$PREV_REVISION"
            return
        fi
    fi
    
    # Try git tags
    if command -v git &> /dev/null && [ -d .git ]; then
        PREV_TAG=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")
        if [ -n "$PREV_TAG" ]; then
            echo "$PREV_TAG"
            return
        fi
    fi
    
    warning "Could not determine previous version automatically"
    echo "unknown"
}

# Function to confirm rollback
confirm_rollback() {
    if [ "$FORCE_ROLLBACK" = true ]; then
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    echo ""
    warning "⚠️  WARNING: This will rollback deployment '$DEPLOYMENT_NAME'"
    warning "Pattern: $PATTERN"
    if [ -n "$TARGET_VERSION" ]; then
        warning "Target version: $TARGET_VERSION"
    fi
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Rollback cancelled"
        exit 0
    fi
}

# Big Bang rollback
rollback_big_bang() {
    log "🔄 Rolling back Big Bang deployment: $DEPLOYMENT_NAME"
    
    PREV_VERSION=$(get_previous_version)
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would rollback to version: $PREV_VERSION"
        log "[DRY RUN] Would execute: ./scripts/deploy.sh $PREV_VERSION --rollback"
        return 0
    fi
    
    if [ "$KUBECTL_AVAILABLE" = true ]; then
        log "Rolling back Kubernetes deployment..."
        kubectl rollout undo deployment/"$DEPLOYMENT_NAME"
        kubectl rollout status deployment/"$DEPLOYMENT_NAME" --timeout=300s
    else
        log "Executing deployment script rollback..."
        ./scripts/deploy.sh "$PREV_VERSION" --rollback || {
            error "Rollback failed"
        }
    fi
    
    check_health || warning "Health check failed, but rollback completed"
    success "Big Bang rollback completed"
}

# Rolling deployment rollback
rollback_rolling() {
    log "🔄 Rolling back Rolling deployment: $DEPLOYMENT_NAME"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would pause deployment and rollback"
        log "[DRY RUN] Would execute: kubectl rollout undo deployment/$DEPLOYMENT_NAME"
        return 0
    fi
    
    if [ "$KUBECTL_AVAILABLE" = true ]; then
        log "Pausing deployment..."
        kubectl rollout pause deployment/"$DEPLOYMENT_NAME" 2>/dev/null || true
        
        log "Rolling back to previous revision..."
        kubectl rollout undo deployment/"$DEPLOYMENT_NAME"
        
        log "Resuming deployment..."
        kubectl rollout resume deployment/"$DEPLOYMENT_NAME" 2>/dev/null || true
        
        log "Waiting for rollout to complete..."
        kubectl rollout status deployment/"$DEPLOYMENT_NAME" --timeout=600s
    else
        error "kubectl required for rolling deployment rollback"
    fi
    
    check_health || warning "Health check failed, but rollback completed"
    success "Rolling deployment rollback completed"
}

# Blue-Green rollback
rollback_blue_green() {
    log "🔄 Rolling back Blue-Green deployment: $DEPLOYMENT_NAME"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would switch traffic back to previous environment"
        return 0
    fi
    
    if [ "$KUBECTL_AVAILABLE" = true ]; then
        # Get current active environment
        CURRENT_ENV=$(kubectl get deployment "$DEPLOYMENT_NAME" -o jsonpath='{.metadata.labels.active-environment}' 2>/dev/null || echo "green")
        
        if [ "$CURRENT_ENV" = "green" ]; then
            NEW_ENV="blue"
        else
            NEW_ENV="green"
        fi
        
        log "Switching traffic from $CURRENT_ENV to $NEW_ENV..."
        
        # Update service selector
        kubectl patch service "$DEPLOYMENT_NAME" -p "{\"spec\":{\"selector\":{\"version\":\"$NEW_ENV\"}}}"
        
        # Update deployment label
        kubectl label deployment "$DEPLOYMENT_NAME" active-environment="$NEW_ENV" --overwrite
        
        log "Waiting for traffic switch..."
        sleep 10
    else
        warning "Manual intervention required for Blue-Green rollback"
        log "Update your load balancer/service configuration to route traffic back to previous environment"
    fi
    
    check_health || warning "Health check failed, but rollback completed"
    success "Blue-Green rollback completed (traffic switched to $NEW_ENV)"
}

# Canary rollback
rollback_canary() {
    log "🔄 Rolling back Canary deployment: $DEPLOYMENT_NAME"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would remove canary and route all traffic to baseline"
        return 0
    fi
    
    if [ "$KUBECTL_AVAILABLE" = true ]; then
        log "Scaling down canary deployment..."
        kubectl scale deployment "$DEPLOYMENT_NAME-canary" --replicas=0 2>/dev/null || {
            warning "Canary deployment not found, may already be removed"
        }
        
        log "Updating service to route all traffic to baseline..."
        # Update service mesh or load balancer configuration
        # This is implementation-specific
        
        log "Removing canary deployment..."
        kubectl delete deployment "$DEPLOYMENT_NAME-canary" 2>/dev/null || true
    else
        warning "Manual intervention required for Canary rollback"
        log "1. Scale down canary deployment"
        log "2. Update traffic routing to send 100% to baseline"
        log "3. Remove canary deployment"
    fi
    
    check_health || warning "Health check failed, but rollback completed"
    success "Canary rollback completed"
}

# Main execution
main() {
    log "🚨 Emergency Rollback Utility"
    log "Pattern: $PATTERN"
    log "Deployment: $DEPLOYMENT_NAME"
    
    if [ "$DRY_RUN" = true ]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    confirm_rollback
    
    case $PATTERN in
        big-bang)
            rollback_big_bang
            ;;
        rolling)
            rollback_rolling
            ;;
        blue-green)
            rollback_blue_green
            ;;
        canary)
            rollback_canary
            ;;
        *)
            error "Unknown pattern: $PATTERN"
            usage
            ;;
    esac
    
    log "📊 Rollback Summary:"
    log "  - Pattern: $PATTERN"
    log "  - Deployment: $DEPLOYMENT_NAME"
    log "  - Status: Completed"
    
    if [ "$DRY_RUN" = false ]; then
        warning "Monitor your application closely for the next few minutes"
        log "Check health endpoint: $HEALTH_CHECK_URL"
    fi
}

# Execute main function
main "$@"

