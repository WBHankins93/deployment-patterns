# 🐳 Docker Compose Examples for Local Testing

This directory contains Docker Compose configurations for testing deployment patterns locally.

## 📁 Contents

- **`docker-compose.big-bang.yml`** - Big Bang deployment testing
- **`docker-compose.rolling.yml`** - Rolling deployment testing
- **`docker-compose.blue-green.yml`** - Blue-Green deployment testing
- **`nginx-*.conf`** - Nginx load balancer configurations
- **`health-check/`** - Simple health check endpoint

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Ports 8000, 8080, 8081 available (or modify in compose files)

### Big Bang Deployment

```bash
# Start services
docker-compose -f docker-compose.big-bang.yml up -d

# Test health endpoint
curl http://localhost:8000/health

# Simulate deployment (causes downtime)
docker-compose -f docker-compose.big-bang.yml down
# Edit docker-compose.big-bang.yml to change image version
docker-compose -f docker-compose.big-bang.yml up -d

# Cleanup
docker-compose -f docker-compose.big-bang.yml down
```

### Rolling Deployment

```bash
# Start with all v1 instances
docker-compose -f docker-compose.rolling.yml up -d --scale app-v1=6 --scale app-v2=0

# Deploy batch 1 (2 v2, 4 v1)
docker-compose -f docker-compose.rolling.yml up -d --scale app-v1=4 --scale app-v2=2

# Wait and verify
sleep 30
curl http://localhost:8000/health

# Deploy batch 2 (4 v2, 2 v1)
docker-compose -f docker-compose.rolling.yml up -d --scale app-v1=2 --scale app-v2=4

# Complete deployment (all v2)
docker-compose -f docker-compose.rolling.yml up -d --scale app-v1=0 --scale app-v2=6

# Cleanup
docker-compose -f docker-compose.rolling.yml down
```

### Blue-Green Deployment

```bash
# Start both environments
docker-compose -f docker-compose.blue-green.yml up -d

# Test Blue (current)
curl http://localhost:8000/blue/health

# Test Green (new)
curl http://localhost:8000/green/health

# Switch traffic to Green
# Edit nginx-blue-green-lb.conf: swap app_active and app_inactive
docker exec blue-green-lb nginx -s reload

# Verify traffic is going to Green
curl http://localhost:8000/health

# Rollback to Blue (if needed)
# Edit nginx-blue-green-lb.conf: swap back
docker exec blue-green-lb nginx -s reload

# Cleanup
docker-compose -f docker-compose.blue-green.yml down
```

## 🔧 Customization

### Using Your Own Application

1. **Replace Image:**
   ```yaml
   # In docker-compose files
   image: your-registry/your-app:v1.0.0
   ```

2. **Update Health Check:**
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
     # Or your app's health check command
   ```

3. **Add Environment Variables:**
   ```yaml
   environment:
     - DATABASE_URL=postgresql://...
     - REDIS_URL=redis://...
   ```

### Adjusting Ports

Edit the `ports` section in docker-compose files:
```yaml
ports:
  - "YOUR_PORT:CONTAINER_PORT"
```

## 📊 Monitoring

### View Logs

```bash
# All services
docker-compose -f docker-compose.rolling.yml logs -f

# Specific service
docker-compose -f docker-compose.rolling.yml logs -f app-v1
```

### Check Container Status

```bash
docker-compose -f docker-compose.rolling.yml ps
```

### Health Check Status

```bash
# Check health
docker inspect <container-name> | grep -A 10 Health
```

## 🧪 Testing Scenarios

### Test Failure Scenarios

1. **Simulate Pod Failure:**
   ```bash
   docker stop <container-name>
   # Observe behavior
   docker start <container-name>
   ```

2. **Simulate Health Check Failure:**
   - Modify health check endpoint to return 500
   - Observe deployment behavior

3. **Simulate Slow Startup:**
   - Add delay to application startup
   - Test health check timeouts

### Test Rollback

1. **Deploy new version**
2. **Simulate issue** (high error rate, slow response)
3. **Execute rollback** (pattern-specific)
4. **Verify recovery**

## 🎯 Integration with Scripts

You can use these Docker Compose files with deployment scripts:

```bash
# In deployment script
export COMPOSE_FILE="examples/docker-compose/docker-compose.rolling.yml"
docker-compose -f $COMPOSE_FILE up -d --scale app-v1=4 --scale app-v2=2
```

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)
- [Deployment Patterns Guide](../../patterns/)

## ⚠️ Notes

- These examples use Nginx as a simple application for demonstration
- Replace with your actual application images
- Adjust resource limits for your environment
- These are for **local testing only** - not production-ready configurations

---

*For production deployments, see Helm charts in `../helm-deployments/`*

