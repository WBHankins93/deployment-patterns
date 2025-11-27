# 🔄 Migration Guide: Moving Between Deployment Patterns

Step-by-step guides for migrating from one deployment pattern to another as your needs evolve.

## 🎯 When to Migrate

### Migration Triggers

- **Growing User Base**: Need zero-downtime deployments
- **Increased Risk Tolerance**: Need safer deployment patterns
- **Infrastructure Growth**: Can support more complex patterns
- **Business Requirements**: Need instant rollback or gradual validation
- **Team Maturity**: Team ready for advanced patterns

---

## 📊 Migration Paths

### Path 1: Big Bang → Rolling

**When:** Need zero-downtime, have load balancer, can handle mixed versions

#### Step 1: Prepare Infrastructure
```bash
# Ensure you have:
# - Load balancer
# - Multiple instances
# - Health checks implemented
```

#### Step 2: Implement Health Checks
```yaml
# Add health check endpoints
livenessProbe:
  httpGet:
    path: /health
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

#### Step 3: Test Rolling in Staging
```bash
# Test rolling deployment
kubectl set image deployment/myapp app=myapp:v2.0.0
kubectl rollout status deployment/myapp
```

#### Step 4: Configure Rolling Strategy
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

#### Step 5: Migrate Production
- Start with small batch sizes
- Monitor closely
- Gradually increase confidence

**Timeline**: 1-2 weeks  
**Risk**: Low  
**Rollback**: Easy (revert to Big Bang config)

---

### Path 2: Rolling → Blue-Green

**When:** Need instant rollback, can afford 2x infrastructure

#### Step 1: Set Up Green Environment
```bash
# Create Green environment
helm install myapp-green ./charts/myapp \
  --set image.tag=v2.0.0 \
  --set environment=green
```

#### Step 2: Test Green Environment
```bash
# Test Green thoroughly
curl http://green.myapp.internal/health
# Run smoke tests
# Validate performance
```

#### Step 3: Implement Traffic Switching
```yaml
# Service with environment selector
apiVersion: v1
kind: Service
spec:
  selector:
    app: myapp
    environment: blue  # Switch to 'green' to change traffic
```

#### Step 4: Test Traffic Switch
```bash
# Test switching mechanism
kubectl patch service myapp -p '{"spec":{"selector":{"environment":"green"}}}'
# Verify traffic routing
# Test rollback
```

#### Step 5: Production Migration
- Deploy Green alongside Blue
- Test Green thoroughly
- Switch traffic during low-traffic period
- Keep Blue for rollback period

**Timeline**: 2-4 weeks  
**Risk**: Medium  
**Rollback**: Instant (switch traffic back)

---

### Path 3: Rolling → Canary

**When:** Need user validation, have traffic splitting capability

#### Step 1: Implement User Segmentation
```yaml
# Service mesh or ingress for traffic splitting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
  - match:
    - headers:
        user-id:
          regex: ".*[02468]$"  # Even IDs → baseline
    route:
    - destination:
        host: myapp-baseline
  - match:
    - headers:
        user-id:
          regex: ".*[13579]$"  # Odd IDs → canary
    route:
    - destination:
        host: myapp-canary
```

#### Step 2: Deploy Canary Infrastructure
```bash
# Deploy canary deployment
kubectl apply -f canary-deployment.yaml
# Configure traffic splitting
```

#### Step 3: Test Canary at Low Percentage
```bash
# Start with 1% traffic
# Monitor metrics
# Compare to baseline
```

#### Step 4: Implement Metrics Comparison
```python
# Compare canary vs baseline
def compare_metrics():
    baseline = get_metrics(variant='baseline')
    canary = get_metrics(variant='canary')
    
    if canary.error_rate > baseline.error_rate * 1.5:
        rollback_canary()
```

#### Step 5: Gradual Rollout
- Start at 1-5%
- Increase gradually (5% → 10% → 25% → 50% → 100%)
- Monitor at each step
- Rollback if issues detected

**Timeline**: 3-4 weeks  
**Risk**: Low  
**Rollback**: Easy (remove canary)

---

### Path 4: Any Pattern → Shadow

**When:** Need production validation with zero user risk

#### Step 1: Set Up Traffic Mirroring
```yaml
# Istio VirtualService with mirroring
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
  - route:
    - destination:
        host: myapp-active
      weight: 100
    mirror:
      host: myapp-shadow
    mirrorPercentage:
      value: 100
```

#### Step 2: Deploy Shadow Environment
```bash
# Deploy shadow version
kubectl apply -f shadow-deployment.yaml
# Configure traffic mirroring
```

#### Step 3: Monitor Shadow Separately
```bash
# Set up separate monitoring
# Compare shadow to active metrics
# Validate shadow performance
```

#### Step 4: Validate Shadow Results
- Run shadow for sufficient duration
- Compare metrics
- Identify issues
- Fix before production deployment

**Timeline**: 2-3 weeks  
**Risk**: Very Low  
**Rollback**: N/A (shadow doesn't serve users)

---

### Path 5: Adding A/B Testing

**When:** Need data-driven feature decisions

#### Step 1: Set Up Analytics
```bash
# Implement analytics tracking
# Set up metrics collection
# Configure user segmentation
```

#### Step 2: Deploy Both Variants
```bash
# Deploy Variant A (control)
kubectl apply -f variant-a-deployment.yaml

# Deploy Variant B (test)
kubectl apply -f variant-b-deployment.yaml
```

#### Step 3: Configure Traffic Splitting
```yaml
# 50/50 split
split_clients "${remote_addr}" $variant {
    50% variant_a_backend;
    50% variant_b_backend;
}
```

#### Step 4: Run Test
- Collect metrics for both variants
- Ensure statistical significance
- Compare key metrics
- Make data-driven decision

**Timeline**: 1-2 weeks  
**Risk**: Low  
**Rollback**: Easy (route to winner)

---

## 🔧 Migration Best Practices

### Planning Phase

1. **Assess Current State**
   - Document current deployment process
   - Identify pain points
   - Define success criteria

2. **Choose Target Pattern**
   - Use [Decision Guide](decision-guide.md)
   - Consider infrastructure capabilities
   - Evaluate team readiness

3. **Create Migration Plan**
   - Timeline
   - Resource requirements
   - Risk assessment
   - Rollback plan

### Execution Phase

1. **Test in Staging First**
   - Never migrate production directly
   - Test thoroughly in staging
   - Validate all scenarios

2. **Gradual Migration**
   - Migrate one service at a time
   - Start with low-risk services
   - Build confidence gradually

3. **Monitor Closely**
   - Watch metrics during migration
   - Have rollback ready
   - Document issues

### Post-Migration

1. **Validate Success**
   - Verify all functionality
   - Check performance metrics
   - Confirm team satisfaction

2. **Optimize**
   - Fine-tune configuration
   - Optimize costs
   - Improve processes

3. **Document**
   - Update procedures
   - Share learnings
   - Train team

---

## ⚠️ Common Migration Challenges

### Challenge 1: Infrastructure Limitations

**Problem:** Current infrastructure doesn't support target pattern

**Solution:**
- Upgrade infrastructure first
- Use managed services
- Consider cloud migration

### Challenge 2: Team Readiness

**Problem:** Team not familiar with new pattern

**Solution:**
- Provide training
- Start with simple migrations
- Pair experienced with less experienced
- Document thoroughly

### Challenge 3: Application Compatibility

**Problem:** Application doesn't support new pattern requirements

**Solution:**
- Refactor application if needed
- Add health checks
- Implement backward compatibility
- Use feature flags

### Challenge 4: Cost Concerns

**Problem:** New pattern is more expensive

**Solution:**
- Calculate total cost (including risk)
- Optimize infrastructure
- Use cost-saving strategies
- Consider phased approach

---

## 📋 Migration Checklist

### Pre-Migration
- [ ] Current state documented
- [ ] Target pattern chosen
- [ ] Migration plan created
- [ ] Team trained
- [ ] Infrastructure ready
- [ ] Staging environment set up
- [ ] Rollback plan prepared

### During Migration
- [ ] Test in staging first
- [ ] Monitor closely
- [ ] Document issues
- [ ] Have rollback ready
- [ ] Communicate progress

### Post-Migration
- [ ] Validate functionality
- [ ] Check performance
- [ ] Optimize configuration
- [ ] Update documentation
- [ ] Train team on new process
- [ ] Review and improve

---

## 🎯 Migration Examples

### Example 1: Startup Growth

**Initial State:** Big Bang for internal dashboard (50 users)

**Migration Path:**
1. **Month 1-3**: Big Bang (acceptable downtime)
2. **Month 4-6**: Migrate to Rolling (zero-downtime needed)
3. **Month 7-12**: Add Canary (user validation needed)

**Timeline**: 12 months  
**Complexity**: Gradual, low risk

---

### Example 2: Enterprise Critical System

**Initial State:** Rolling for payment API

**Migration Path:**
1. **Week 1-2**: Set up Blue-Green infrastructure
2. **Week 3**: Test Blue-Green in staging
3. **Week 4**: Migrate production to Blue-Green
4. **Week 5+**: Use Blue-Green for instant rollback

**Timeline**: 5 weeks  
**Complexity**: Medium, higher risk (critical system)

---

### Example 3: Adding Validation

**Initial State:** Rolling for web application

**Migration Path:**
1. **Week 1**: Set up Shadow infrastructure
2. **Week 2**: Deploy Shadow for validation
3. **Week 3-4**: Validate with shadow
4. **Week 5**: Proceed to production using Rolling

**Timeline**: 5 weeks  
**Complexity**: Medium, low risk (validation only)

---

## 📚 Related Resources

- **[Decision Guide](decision-guide.md)** - Choose target pattern
- **[Best Practices](best-practices.md)** - Migration best practices
- **[Getting Started](getting-started.md)** - Learn patterns first
- **[Cost Analysis](cost-analysis.md)** - Understand cost implications

---

*Migration is a journey, not a destination. Start simple and evolve as your needs grow.*

