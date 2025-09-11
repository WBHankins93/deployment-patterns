## 📄 Rolling Deployment ✅

### 🔄 What It Is
**Rolling Deployment** gradually replaces instances of the old version of your application with the new one, in **batches**. It avoids downtime by updating only a subset of servers at a time.

Most cloud platforms and orchestrators like Kubernetes support this natively.

### 📊 Visual Overview
```
Step 1                Step 2                Step 3                Final
┌─────────────┐       ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ v1 │ v1 │ v1│ -->   │ v2 │ v1 │ v1│  -->  │ v2 │ v2 │ v1│  -->  │ v2 │ v2 │ v2│
│ ┌─┐ ┌─┐ ┌─┐ │       │ ┌─┐ ┌─┐ ┌─┐ │       │ ┌─┐ ┌─┐ ┌─┐ │       │ ┌─┐ ┌─┐ ┌─┐ │
│ │S│ │S│ │S│ │       │ │S│ │S│ │S│ │       │ │S│ │S│ │S│ │       │ │S│ │S│ │S│ │
│ └─┘ └─┘ └─┘ │       │ └─┘ └─┘ └─┘ │       │ └─┘ └─┘ └─┘ │       │ └─┘ └─┘ └─┘ │
└─────────────┘       └─────────────┘       └─────────────┘       └─────────────┘
Deploy Batch 1        Deploy Batch 2        Deploy Batch 3         Complete!
✅ Health Check       ✅ Health Check       ✅ Health Check       🎉 All Updated
```

**Risk Level**: 🟡 Medium | **Complexity**: 🟡 Medium | **Downtime**: 🟢 None

---

### ✅ When to Use It
- Production environments that require high availability
- Systems where gradual rollout is safer
- When Big Bang is too risky but Blue-Green is overkill
- Applications with stateless, horizontally scalable architecture
- When you need to validate each step before proceeding

---

### 📊 Pros
- ✅ Minimal to zero downtime
- ✅ Lower risk during deploy
- ✅ Built-in support in tools like K8s, ECS, etc.
- ✅ Can halt deployment if issues arise
- ✅ Maintains service capacity throughout deployment
- ✅ Natural load balancing during deployment

---

### ❌ Cons
- ❌ Rollbacks mid-way can be complex (mixed state)
- ❌ Longer total deploy time
- ❌ Requires good health checks to abort on failure
- ❌ Version mixing during deployment can cause issues
- ❌ More complex monitoring during deployment

---

### 🛠 Example CI/CD Snippet
```yaml
# GitHub Actions: Rolling Deployment
- name: Deploy to batch of servers
  run: ./scripts/rolling-batch-deploy.sh
  env:
    BATCH_SIZE: 2
    HEALTH_CHECK_URL: https://api.example.com/health
    MAX_PARALLEL_BATCHES: 1
```

🔗 **See full example**: [`rolling-deploy.yml`](../examples/github-actions/rolling-deploy.yml)  
📂 **Deploy script reference**: [`rolling-batch-deploy.sh`](../../scripts/rolling-batch-deploy.sh)

#### Kubernetes Rolling Update
```yaml
# k8s-rolling-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Keep 5/6 pods running
      maxSurge: 2           # Allow up to 8 pods during update
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:{{ .Values.image.tag }}
        ports:
        - containerPort: 8080
        livenessProbe:         # Critical for rolling updates
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:        # Ensures traffic only goes to ready pods
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
```

#### Helm Rolling Update Strategy
```yaml
# values.yaml
deployment:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  
healthCheck:
  enabled: true
  path: /health
  
readinessProbe:
  enabled: true
  path: /ready
  initialDelaySeconds: 10
  periodSeconds: 5
```

---

### 📈 Monitoring & Alerting
Critical metrics to monitor during rolling deployments:

```yaml
# Sample Prometheus Alerts
groups:
- name: rolling-deployment
  rules:
  - alert: RollingDeploymentStuck
    expr: kube_deployment_status_replicas != kube_deployment_status_updated_replicas
    for: 10m
    annotations:
      summary: "Rolling deployment has been stuck for 10+ minutes"

  - alert: HighErrorRateDuringRolling
    expr: rate(http_requests_total{code=~"5.."}[2m]) > 0.05
    for: 1m
    annotations:
      summary: "Error rate increased during rolling deployment"
      
  - alert: PodRestartsDuringDeploy
    expr: increase(kube_pod_container_status_restarts_total[5m]) > 3
    for: 1m
    annotations:
      summary: "Multiple pod restarts detected during deployment"
```

**Key Metrics Dashboard:**
- Pod readiness status
- Request success rate per batch
- Response latency trends
- Active connections during rollover

---

### 🔄 Rollback Strategy
Rolling deployments offer several rollback approaches:

**1. Automatic Rollback (Kubernetes)**
```bash
# Rollback to previous revision
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=2

# Check rollout status
kubectl rollout status deployment/myapp
```

**2. Manual Halt and Rollback**
```bash
# Pause the rollout
kubectl rollout pause deployment/myapp

# After investigation, resume or undo
kubectl rollout resume deployment/myapp
# OR
kubectl rollout undo deployment/myapp
```

**3. Custom Script Rollback**
```bash
#!/bin/bash
# rolling-rollback.sh
PREVIOUS_VERSION=$(kubectl get deployment myapp -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
echo "Rolling back from current deployment..."
kubectl rollout undo deployment/myapp
kubectl rollout status deployment/myapp --timeout=300s
```

---

### 💡 Real-World Example
We used rolling deployments at a previous startup to roll out updates to our Kubernetes cluster. Each batch deployed to 2 pods at a time out of 8 total pods. If the error rate spiked during health checks, the rollout automatically paused and alerted the on-call engineer.

**Specific Implementation:**
- **Environment**: EKS cluster with 8 application pods
- **Batch Size**: 2 pods (25% of capacity)
- **Health Check**: HTTP endpoint `/health` with 10s timeout
- **Rollout Time**: ~4 minutes for full deployment
- **Rollback Time**: ~2 minutes using `kubectl rollout undo`

This setup gave us the confidence to deploy during the day instead of after-hours, reducing our mean time to deployment from 24 hours to 2 hours.

**Success Metrics:**
- 99.9% deployment success rate
- 0 customer-impacting incidents during deployment
- 60% reduction in deployment-related downtime

---

### ⚠️ Gotchas to Watch For
- 🧩 **Misconfigured health checks** can silently let broken code through
- 🔙 **Rollback logic** must be clear if errors surface mid-deploy
- 🧠 **Observability** is crucial — dashboards and alerts must be in place
- 🔗 **Version compatibility** issues during mixed-version state
- 📊 **Resource constraints** can cause deployment to hang
- 🗄️ **Database migrations** need special consideration

**Common Failure Scenarios:**
1. **Health check passes but app is broken** → Implement deeper health checks
2. **Deployment hangs on one batch** → Set proper timeouts and resource limits
3. **Mixed versions cause API incompatibility** → Use backward-compatible changes
4. **Load balancer doesn't respect readiness** → Configure proper probe endpoints

---

### 🧪 Validation Strategy
**Per-Batch Validation:**
- ✅ Health endpoint responds with 200 status
- ✅ Application logs show successful startup
- ✅ No increase in error rate for 60 seconds
- ✅ Database connections are healthy
- ✅ Integration tests pass for new pods

**Overall Deployment Validation:**
- ✅ All pods reach Ready state
- ✅ Service discovery updated correctly
- ✅ End-to-end user journey test passes
- ✅ Performance metrics within acceptable range
- ✅ No alerts firing after deployment

**Automated Rollback Triggers:**
- ❌ Health check failure rate > 20%
- ❌ Error rate increase > 5x baseline
- ❌ Response time increase > 2x baseline
- ❌ Pod crash loop detected

---

### 📋 Decision Matrix
| Factor | Score (1-5) | Notes |
|--------|-------------|--------|
| Speed | ⭐⭐⭐ | Moderate deployment speed |
| Safety | ⭐⭐⭐⭐ | Good safety with health checks |
| Complexity | ⭐⭐⭐ | Moderate complexity |
| Rollback Speed | ⭐⭐⭐⭐ | Quick automated rollback |
| Resource Usage | ⭐⭐⭐⭐ | Minimal extra resources |
| Zero Downtime | ⭐⭐⭐⭐⭐ | True zero downtime |

---

### 🧠 TL;DR
Rolling deployments are **ideal for high-uptime systems** where slow, safe rollout is preferred over instant switchovers.

**Use when:**
- You have automated monitoring in place
- You want to minimize user disruption
- Your application is stateless and horizontally scalable
- You can tolerate temporary mixed-version states

**Avoid when:**
- You can't afford a mixed-version state
- You lack observability or batch health validation
- Your application requires all instances to be identical
- Database schema changes are not backward compatible