# 🔧 Deployment Troubleshooting Guide

Common issues, solutions, and debugging strategies for deployment patterns.

## 🎯 Quick Reference

| Issue | Pattern | Quick Fix |
|-------|---------|-----------|
| Service down after deploy | Big Bang | Immediate rollback |
| Deployment stuck | Rolling | Pause and investigate |
| Health checks failing | All | Check logs, verify endpoints |
| Mixed versions causing errors | Rolling | Pause rollout, verify compatibility |
| Traffic not switching | Blue-Green | Check load balancer/DNS |
| Canary showing errors | Canary | Reduce traffic or rollback |

---

## 🚨 Common Issues by Pattern

### Big Bang Deployment Issues

#### Issue: Service Completely Down After Deployment

**Symptoms:**
- All health checks failing
- Zero successful requests
- Complete service outage

**Diagnosis:**
```bash
# Check pod/container status
kubectl get pods -l app=myapp
kubectl describe pod <pod-name>

# Check application logs
kubectl logs <pod-name> --tail=100

# Check service endpoints
kubectl get endpoints <service-name>
```

**Common Causes:**
1. Application crash on startup
2. Database connection failures
3. Configuration errors
4. Missing environment variables
5. Port binding issues

**Solutions:**
1. **Immediate Rollback:**
   ```bash
   ./scripts/deploy.sh <previous-version> --rollback
   # OR
   kubectl rollout undo deployment/myapp
   ```

2. **Fix and Redeploy:**
   - Check application logs for startup errors
   - Verify configuration files
   - Test database connectivity
   - Validate environment variables

3. **Prevention:**
   - Add comprehensive health checks
   - Test in staging first
   - Use configuration validation
   - Implement startup probes

---

#### Issue: Database Migration Failures

**Symptoms:**
- Application starts but fails on database operations
- Migration errors in logs
- Data inconsistency warnings

**Diagnosis:**
```bash
# Check migration status
kubectl logs <pod-name> | grep -i migration

# Verify database connectivity
kubectl exec -it <pod-name> -- psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"
```

**Solutions:**
1. **Rollback Database:**
   ```bash
   # If migration supports rollback
   ./migrations/rollback.sh
   ```

2. **Manual Fix:**
   - Review migration scripts
   - Check database logs
   - Verify schema compatibility

3. **Prevention:**
   - Test migrations in staging
   - Use transactional migrations
   - Backup database before migration
   - Implement migration versioning

---

### Rolling Deployment Issues

#### Issue: Deployment Stuck on One Batch

**Symptoms:**
- Some pods updated, others not
- Deployment progress unchanged
- Health checks failing for new pods

**Diagnosis:**
```bash
# Check deployment status
kubectl rollout status deployment/myapp

# Check pod events
kubectl describe pod <stuck-pod-name>

# Check resource constraints
kubectl top nodes
kubectl top pods
```

**Common Causes:**
1. Resource constraints (CPU/memory)
2. Image pull failures
3. Health check timeouts
4. Node unavailability
5. Pod disruption budget conflicts

**Solutions:**
1. **Pause and Investigate:**
   ```bash
   kubectl rollout pause deployment/myapp
   # Investigate issue
   kubectl rollout resume deployment/myapp
   ```

2. **Fix Resource Issues:**
   ```bash
   # Scale up cluster
   # OR adjust resource requests/limits
   kubectl set resources deployment/myapp --requests=cpu=200m,memory=256Mi
   ```

3. **Rollback if Needed:**
   ```bash
   kubectl rollout undo deployment/myapp
   ```

---

#### Issue: Mixed Versions Causing Errors

**Symptoms:**
- API compatibility errors
- Feature flags mismatched
- Data format incompatibilities
- Inter-service communication failures

**Diagnosis:**
```bash
# Check version distribution
kubectl get pods -l app=myapp -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Check error logs
kubectl logs -l app=myapp --tail=100 | grep -i error
```

**Solutions:**
1. **Pause Deployment:**
   ```bash
   kubectl rollout pause deployment/myapp
   ```

2. **Verify Compatibility:**
   - Check API contracts
   - Verify feature flag compatibility
   - Test inter-service communication

3. **Options:**
   - **Complete Rollout**: If compatible, resume
   - **Rollback**: If incompatible, rollback all
   - **Fix Compatibility**: Update code for backward compatibility

**Prevention:**
- Implement API versioning
- Use feature flags for gradual rollouts
- Test mixed-version scenarios
- Maintain backward compatibility

---

#### Issue: Health Checks Failing Intermittently

**Symptoms:**
- Pods marked as not ready
- Health check endpoint sometimes fails
- Deployment progress slow or stuck

**Diagnosis:**
```bash
# Test health endpoint manually
kubectl exec -it <pod-name> -- curl http://localhost:8080/health

# Check health check configuration
kubectl get deployment myapp -o yaml | grep -A 10 readinessProbe

# Check application startup time
kubectl logs <pod-name> | grep -i "started\|ready"
```

**Solutions:**
1. **Adjust Health Check Timing:**
   ```yaml
   readinessProbe:
     initialDelaySeconds: 15  # Increase if app starts slowly
     periodSeconds: 5
     timeoutSeconds: 3
     failureThreshold: 3
   ```

2. **Improve Health Endpoint:**
   - Check all dependencies (DB, cache, etc.)
   - Return proper HTTP status codes
   - Keep response time < 100ms

3. **Use Startup Probe:**
   ```yaml
   startupProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 0
     periodSeconds: 5
     failureThreshold: 30  # Allow up to 2.5 minutes for startup
   ```

---

### Blue-Green Deployment Issues

#### Issue: Traffic Not Switching to Green Environment

**Symptoms:**
- Green environment healthy but no traffic
- Load balancer still pointing to Blue
- DNS not updated

**Diagnosis:**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Check ingress configuration
kubectl get ingress <ingress-name> -o yaml

# Test both environments
curl http://blue.example.com/health
curl http://green.example.com/health
```

**Solutions:**
1. **Manual Traffic Switch:**
   ```bash
   # Update service selector
   kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'
   
   # OR update ingress
   kubectl patch ingress myapp -p '{"spec":{"rules":[{"host":"myapp.com","http":{"paths":[{"path":"/","backend":{"service":{"name":"myapp-green"}}}}]}}]}'
   ```

2. **Verify Load Balancer:**
   - Check load balancer configuration
   - Verify DNS records
   - Test from multiple locations

3. **Automated Switch Script:**
   ```bash
   ./scripts/blue-green-switch.sh green
   ```

---

#### Issue: Green Environment Resource Exhaustion

**Symptoms:**
- Green environment slow or failing
- High CPU/memory usage
- Pods being evicted

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -l version=green

# Check node resources
kubectl top nodes

# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 "Limits\|Requests"
```

**Solutions:**
1. **Scale Up:**
   ```bash
   kubectl scale deployment myapp-green --replicas=6
   ```

2. **Adjust Resources:**
   ```bash
   kubectl set resources deployment/myapp-green \
     --requests=cpu=500m,memory=512Mi \
     --limits=cpu=1000m,memory=1Gi
   ```

3. **Add Nodes:**
   - Scale cluster if needed
   - Consider autoscaling

---

### Canary Deployment Issues

#### Issue: Canary Showing High Error Rate

**Symptoms:**
- Canary error rate > baseline
- User complaints from canary users
- Performance degradation

**Diagnosis:**
```bash
# Compare error rates
# Canary
kubectl logs -l version=canary --tail=100 | grep -c "ERROR"
# Baseline
kubectl logs -l version=baseline --tail=100 | grep -c "ERROR"

# Check metrics
# Use monitoring dashboard to compare
```

**Solutions:**
1. **Immediate Actions:**
   ```bash
   # Reduce canary traffic
   kubectl patch service myapp -p '{"spec":{"selector":{"version":"baseline"}}}'
   
   # OR rollback canary
   kubectl delete deployment myapp-canary
   ```

2. **Investigate:**
   - Compare canary logs to baseline
   - Check for configuration differences
   - Verify feature flags
   - Review recent changes

3. **Fix and Retry:**
   - Fix identified issues
   - Test in staging
   - Redeploy canary with fix

---

#### Issue: Canary Traffic Not Routing Correctly

**Symptoms:**
- All traffic going to baseline
- Canary pods idle
- Load balancer not splitting traffic

**Diagnosis:**
```bash
# Check service configuration
kubectl get service myapp -o yaml

# Check ingress rules
kubectl get ingress -o yaml

# Verify pod labels
kubectl get pods -l version=canary
```

**Solutions:**
1. **Fix Service Selector:**
   ```yaml
   # Ensure service can route to both
   apiVersion: v1
   kind: Service
   spec:
     selector:
       app: myapp  # Common label, not version-specific
   ```

2. **Use Ingress for Traffic Splitting:**
   ```yaml
   # Use service mesh or ingress controller
   # Example: Istio VirtualService
   ```

3. **Verify Load Balancer:**
   - Check load balancer configuration
   - Verify traffic splitting rules
   - Test from multiple sources

---

## 🔍 General Debugging Strategies

### Step 1: Gather Information

```bash
# Deployment status
kubectl get deployments
kubectl rollout status deployment/myapp

# Pod status
kubectl get pods -l app=myapp
kubectl describe pod <pod-name>

# Service status
kubectl get services
kubectl get endpoints

# Events
kubectl get events --sort-by='.lastTimestamp'
```

### Step 2: Check Logs

```bash
# Application logs
kubectl logs <pod-name> --tail=100 -f

# Previous container (if crashed)
kubectl logs <pod-name> --previous

# All pods
kubectl logs -l app=myapp --tail=50

# Specific container in pod
kubectl logs <pod-name> -c <container-name>
```

### Step 3: Verify Configuration

```bash
# Deployment configuration
kubectl get deployment myapp -o yaml

# ConfigMaps
kubectl get configmap
kubectl describe configmap <config-name>

# Secrets (metadata only)
kubectl get secrets
kubectl describe secret <secret-name>

# Environment variables
kubectl exec <pod-name> -- env | sort
```

### Step 4: Test Connectivity

```bash
# Port forward for testing
kubectl port-forward <pod-name> 8080:8080

# Test from inside cluster
kubectl run test-pod --image=curlimages/curl --rm -it -- \
  curl http://myapp-service:80/health

# DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup myapp-service
```

---

## 🛠️ Emergency Procedures

### Complete Service Outage

```bash
# 1. Immediate rollback
kubectl rollout undo deployment/myapp

# 2. Scale down problematic deployment
kubectl scale deployment/myapp --replicas=0

# 3. Restore from backup (if needed)
# Database, configuration, etc.

# 4. Notify stakeholders
# Slack, PagerDuty, etc.
```

### Data Corruption Risk

```bash
# 1. Stop all traffic immediately
kubectl scale deployment/myapp --replicas=0

# 2. Isolate affected environment
# Network policies, service removal

# 3. Assess damage
# Database checks, data validation

# 4. Restore from backup if needed
```

### Security Incident

```bash
# 1. Immediate isolation
kubectl scale deployment/myapp --replicas=0

# 2. Preserve evidence
kubectl get pods -o yaml > incident-pods.yaml
kubectl logs <pod-name> > incident-logs.txt

# 3. Rotate credentials
# Update secrets, API keys, etc.

# 4. Security team notification
```

---

## 📋 Prevention Checklist

### Pre-Deployment
- [ ] Tested in staging environment
- [ ] Health checks verified
- [ ] Database migrations tested
- [ ] Configuration validated
- [ ] Resource limits appropriate
- [ ] Rollback procedure tested
- [ ] Monitoring dashboards ready
- [ ] On-call engineer notified

### During Deployment
- [ ] Monitoring dashboard open
- [ ] Logs streaming
- [ ] Ready to pause/rollback
- [ ] Communication channels open

### Post-Deployment
- [ ] Health checks passing
- [ ] Error rates normal
- [ ] Performance metrics acceptable
- [ ] User feedback monitored
- [ ] Documentation updated

---

## 📚 Additional Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [SRE Incident Response](https://sre.google/sre-book/managing-incidents/)
- [Debugging Production Issues](https://github.com/danluu/debugging-stories)

---

*This guide is part of the Deployment Patterns Guide. For pattern-specific details, see individual pattern documentation in `../patterns/`.*

