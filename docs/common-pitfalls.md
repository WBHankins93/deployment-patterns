# ⚠️ Common Pitfalls & Anti-Patterns

Learn from common mistakes to avoid deployment failures and production incidents.

## 🚨 Critical Pitfalls

### 1. Deploying Without Testing

**The Mistake:**
```bash
# "It works on my machine, let's deploy!"
git push origin main
# Deploy directly to production
```

**Why It's Bad:**
- Code that works locally may fail in production
- Different environments have different configurations
- Dependencies may behave differently

**The Fix:**
- ✅ Always test in staging first
- ✅ Run automated test suites
- ✅ Test in production-like environment
- ✅ Use CI/CD pipelines with automated tests

---

### 2. No Rollback Plan

**The Mistake:**
- Deploying without knowing how to revert
- Not testing rollback procedures
- Assuming everything will work

**Why It's Bad:**
- When things break, you're stuck
- Recovery takes much longer
- User impact is maximized

**The Fix:**
- ✅ Document rollback procedure before deploying
- ✅ Test rollback in staging
- ✅ Keep previous version available
- ✅ Know rollback time requirements

---

### 3. Skipping Health Checks

**The Mistake:**
```yaml
# No health checks configured
containers:
  - name: app
    image: myapp:v2.0.0
    # Missing livenessProbe and readinessProbe
```

**Why It's Bad:**
- Broken instances may receive traffic
- Issues go undetected
- Automatic recovery doesn't work
- Deployment appears successful but service is broken

**The Fix:**
- ✅ Always implement health checks
- ✅ Test health check endpoints
- ✅ Use both liveness and readiness probes
- ✅ Set appropriate timeouts and thresholds

---

### 4. Deploying During Peak Hours

**The Mistake:**
- Deploying to production at 2 PM on a weekday
- No consideration of user traffic patterns
- Deploying during business-critical periods

**Why It's Bad:**
- Maximum user impact if something goes wrong
- Harder to rollback under pressure
- Team stress increases
- Business impact is highest

**The Fix:**
- ✅ Schedule deployments during low-traffic periods
- ✅ Use maintenance windows when appropriate
- ✅ Consider time zones for global services
- ✅ Communicate deployment schedule

---

### 5. Ignoring Monitoring Alerts

**The Mistake:**
- Deploying and walking away
- Not watching dashboards
- Ignoring error rate increases
- "It will probably be fine"

**Why It's Bad:**
- Issues go undetected until users complain
- Problems compound over time
- Rollback becomes more difficult
- Data corruption or cascading failures

**The Fix:**
- ✅ Monitor actively during deployment
- ✅ Set up alerts before deploying
- ✅ Have dashboards ready
- ✅ Watch for at least 15-30 minutes post-deploy

---

## 🎯 Pattern-Specific Pitfalls

### Big Bang Deployment Pitfalls

#### Pitfall: No Maintenance Window Communication
**Problem:** Users don't know about downtime
**Solution:** 
- Announce maintenance windows in advance
- Use status pages
- Send notifications

#### Pitfall: Database Migrations Without Backup
**Problem:** Can't rollback database changes
**Solution:**
- Always backup before migrations
- Use reversible migrations
- Test migrations in staging

#### Pitfall: Deploying Breaking Changes
**Problem:** New version incompatible with existing data/config
**Solution:**
- Maintain backward compatibility
- Use feature flags for breaking changes
- Gradual migration strategy

---

### Rolling Deployment Pitfalls

#### Pitfall: Too Large Batch Sizes
**Problem:** 
```yaml
# Updating 50% of instances at once
maxUnavailable: 50%
```
**Solution:**
- Start with small batches (1-2 instances)
- Increase gradually as confidence grows
- Monitor each batch before proceeding

#### Pitfall: Ignoring Mixed Version State
**Problem:** Versions incompatible with each other
**Solution:**
- Ensure backward compatibility
- Test mixed-version scenarios
- Use API versioning
- Coordinate database changes

#### Pitfall: No Health Check Between Batches
**Problem:** Continuing deployment despite failures
**Solution:**
- Wait for health checks between batches
- Pause on errors
- Automatic rollback on failure

---

### Blue-Green Deployment Pitfalls

#### Pitfall: Not Testing Green Environment
**Problem:** Switching traffic to untested environment
**Solution:**
- Thoroughly test Green before switching
- Run smoke tests
- Validate all critical paths
- Compare metrics

#### Pitfall: Deleting Blue Too Quickly
**Problem:** Can't rollback if Green has issues
**Solution:**
- Keep Blue running for rollback period
- Monitor Green for extended period
- Have cleanup delay (e.g., 1 hour)

#### Pitfall: Environment Drift
**Problem:** Blue and Green environments differ
**Solution:**
- Use Infrastructure as Code
- Ensure identical configurations
- Validate environment parity
- Document differences if any

---

### Canary Deployment Pitfalls

#### Pitfall: Starting with Large Canary Percentage
**Problem:** Too many users affected if canary fails
**Solution:**
- Start with 1-5% traffic
- Gradually increase
- Monitor closely at each step

#### Pitfall: Inconsistent User Assignment
**Problem:** Same user sees different versions
**Solution:**
- Use consistent hashing
- Store assignment in session/cookie
- Document assignment logic

#### Pitfall: Not Comparing Metrics
**Problem:** Canary looks good but actually worse
**Solution:**
- Compare canary to baseline
- Use statistical significance
- Monitor multiple metrics
- Set clear success criteria

---

### Shadow Deployment Pitfalls

#### Pitfall: Shadow Writes to Production Database
**Problem:** Corrupting production data
**Solution:**
- Use read-only shadow or separate database
- Disable writes in shadow
- Use database replicas

#### Pitfall: External API Calls from Shadow
**Problem:** Duplicate charges or side effects
**Solution:**
- Mock external APIs in shadow
- Use test API keys
- Disable external calls
- Use feature flags

#### Pitfall: Ignoring Shadow Metrics
**Problem:** Not learning from shadow deployment
**Solution:**
- Monitor shadow separately
- Compare to active metrics
- Document findings
- Act on issues found

---

### A/B Testing Pitfalls

#### Pitfall: Insufficient Sample Size
**Problem:** Results not statistically significant
**Solution:**
- Calculate required sample size
- Run test for sufficient duration
- Use statistical tools
- Don't end test prematurely

#### Pitfall: Changing Test Mid-Run
**Problem:** Invalidating test results
**Solution:**
- Lock test configuration
- Don't change traffic split
- Don't modify variants
- Document any changes

#### Pitfall: Wrong Success Metric
**Problem:** Optimizing for wrong goal
**Solution:**
- Define success criteria upfront
- Align with business goals
- Monitor multiple metrics
- Consider long-term impact

---

## 🔧 Technical Pitfalls

### Configuration Management

#### Pitfall: Hardcoded Configuration
```python
# Bad
DATABASE_URL = "postgresql://prod-db:5432/app"
```

**Solution:**
```python
# Good
DATABASE_URL = os.environ.get('DATABASE_URL')
```

#### Pitfall: Secrets in Code
```yaml
# Bad - Never do this!
apiKey: "sk_live_1234567890"
```

**Solution:**
- Use secret management systems
- Environment variables
- Kubernetes secrets
- Never commit secrets

---

### Resource Management

#### Pitfall: Insufficient Resources
**Problem:** Deployment fails due to resource constraints
**Solution:**
- Plan resource requirements
- Monitor capacity
- Scale before deploying
- Use autoscaling

#### Pitfall: Resource Exhaustion
**Problem:** New version uses more resources
**Solution:**
- Test resource usage
- Set appropriate limits
- Monitor during deployment
- Have headroom

---

### Database Migrations

#### Pitfall: Non-Reversible Migrations
**Problem:** Can't rollback database changes
**Solution:**
- Design reversible migrations
- Test rollback procedures
- Backup before migrations
- Use migration tools

#### Pitfall: Long-Running Migrations
**Problem:** Locks database during deployment
**Solution:**
- Use online migration tools
- Migrate in stages
- Test migration time
- Schedule appropriately

---

## 👥 Organizational Pitfalls

### Communication

#### Pitfall: Deploying Without Notifying Team
**Problem:** No one available if issues arise
**Solution:**
- Notify team in advance
- Use communication channels
- Have on-call available
- Schedule deployments

#### Pitfall: No Post-Deployment Review
**Problem:** Repeating same mistakes
**Solution:**
- Review what went well
- Document issues
- Share learnings
- Update procedures

---

### Process

#### Pitfall: Bypassing Code Review
**Problem:** Bugs reach production
**Solution:**
- Require code reviews
- Use pull request process
- Automated checks
- Quality gates

#### Pitfall: No Deployment Documentation
**Problem:** Can't reproduce or understand deployments
**Solution:**
- Document deployment process
- Keep deployment logs
- Version control everything
- Update runbooks

---

## 🎯 Anti-Patterns to Avoid

### 1. "It Works on My Machine"
- **Problem:** Assuming local success = production success
- **Solution:** Always test in staging/production-like environment

### 2. "We'll Fix It in Production"
- **Problem:** Deploying known issues
- **Solution:** Fix issues before deploying

### 3. "Just One More Feature"
- **Problem:** Scope creep during deployment
- **Solution:** Stick to planned deployment scope

### 4. "We Don't Need to Test Rollback"
- **Problem:** Rollback fails when needed
- **Solution:** Always test rollback procedures

### 5. "Monitoring Can Wait"
- **Problem:** Flying blind during deployment
- **Solution:** Set up monitoring before deploying

### 6. "This Change is Small, It's Safe"
- **Problem:** Small changes can have big impacts
- **Solution:** Treat all production changes seriously

### 7. "We Can Deploy Anytime"
- **Problem:** Deploying at wrong times
- **Solution:** Schedule deployments appropriately

### 8. "We'll Monitor It Later"
- **Problem:** Issues go undetected
- **Solution:** Monitor actively during and after deployment

---

## 🛡️ Prevention Strategies

### Pre-Deployment
- ✅ Comprehensive testing
- ✅ Code review
- ✅ Staging validation
- ✅ Rollback plan
- ✅ Team notification

### During Deployment
- ✅ Active monitoring
- ✅ Health check validation
- ✅ Gradual rollout
- ✅ Error detection
- ✅ Ready to pause/rollback

### Post-Deployment
- ✅ Extended monitoring
- ✅ Validation testing
- ✅ Team availability
- ✅ Documentation
- ✅ Review and learn

---

## 📚 Learn More

- **[Best Practices](best-practices.md)** - What to do
- **[Troubleshooting Guide](troubleshooting.md)** - How to fix issues
- **[Getting Started](getting-started.md)** - Beginner's guide
- **[Decision Guide](decision-guide.md)** - Choose the right pattern

---

*Remember: Everyone makes mistakes. The key is learning from them and building processes to prevent them.*

