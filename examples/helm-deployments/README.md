# 🏗️ Helm Chart Examples

This directory contains production-ready Helm charts demonstrating different deployment patterns for Kubernetes.

## 📑 Table of Contents

- [📦 Available Charts](#-available-charts)
- [🚀 Quick Start](#-quick-start)
- [📋 Big Bang Deployment](#-big-bang-deployment)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Rollback](#rollback)
  - [Dry Run](#dry-run)
- [🔄 Rolling Deployment](#-rolling-deployment)
  - [Install](#install-1)
  - [Monitor Rollout](#monitor-rollout)
  - [Control Rollout](#control-rollout)
  - [Batch Configuration](#batch-configuration)
- [⚙️ Configuration Examples](#️-configuration-examples)
  - [Environment-Specific Deployments](#environment-specific-deployments)
  - [Custom Values File](#custom-values-file)
- [🔍 Troubleshooting](#-troubleshooting)
  - [Chart Issues](#chart-issues)
  - [Deployment Issues](#deployment-issues)
  - [Health Check Failures](#health-check-failures)
- [📊 Monitoring Integration](#-monitoring-integration)
  - [Prometheus Metrics](#prometheus-metrics)
  - [Grafana Dashboards](#grafana-dashboards)
- [🛡️ Security Considerations](#️-security-considerations)
  - [Image Security](#image-security)
  - [Network Policies](#network-policies)
- [🧪 Testing](#-testing)
  - [Local Testing with Minikube](#local-testing-with-minikube)
  - [Automated Testing](#automated-testing)
- [📚 Additional Resources](#-additional-resources)
- [🆘 Emergency Procedures](#-emergency-procedures)
  - [Quick Rollback](#quick-rollback)
  - [Emergency Scale Down](#emergency-scale-down)

---

## 📦 Available Charts

| Chart | Pattern | Strategy | Use Case |
|-------|---------|----------|----------|
| `big-bang-chart/` | Big Bang | `Recreate` | Internal tools, maintenance windows |
| `rolling-chart/` | Rolling | `RollingUpdate` | Production APIs, zero downtime |

---

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (1.19+)
- Helm 3.x installed
- kubectl configured

### Validation
```bash
# Validate charts before deployment
helm lint big-bang-chart/
helm lint rolling-chart/
```

---

## 📋 Big Bang Deployment

### Install
```bash
# Deploy with big bang strategy
helm install myapp ./big-bang-chart \
  --set image.tag=v2.0.0 \
  --set strategy.type=Recreate \
  --wait --timeout=300s
```

### Upgrade
```bash
# Upgrade (causes downtime)
helm upgrade myapp ./big-bang-chart \
  --set image.tag=v2.1.0 \
  --wait --timeout=300s
```

### Rollback
```bash
# Quick rollback
helm rollback myapp 1

# Rollback to specific revision
helm history myapp
helm rollback myapp 3
```

### Dry Run
```bash
# Test without applying
helm install myapp ./big-bang-chart \
  --set image.tag=v2.0.0 \
  --dry-run --debug
```

---

## 🔄 Rolling Deployment

### Install
```bash
# Deploy with rolling strategy
helm install myapp ./rolling-chart \
  --set image.tag=v2.0.0 \
  --set strategy.type=RollingUpdate \
  --set strategy.rollingUpdate.maxUnavailable=1 \
  --set strategy.rollingUpdate.maxSurge=2 \
  --wait --timeout=600s
```

### Monitor Rollout
```bash
# Watch deployment progress
kubectl rollout status deployment/myapp-rolling-app

# Monitor pods during update
kubectl get pods -l app.kubernetes.io/name=myapp -w
```

### Control Rollout
```bash
# Pause rollout if issues detected
kubectl rollout pause deployment/myapp-rolling-app

# Resume rollout
kubectl rollout resume deployment/myapp-rolling-app

# Rollback via kubectl (faster than Helm)
kubectl rollout undo deployment/myapp-rolling-app
```

### Batch Configuration
```bash
# Smaller batches (safer)
helm upgrade myapp ./rolling-chart \
  --set strategy.rollingUpdate.maxUnavailable=1 \
  --set strategy.rollingUpdate.maxSurge=1

# Larger batches (faster)
helm upgrade myapp ./rolling-chart \
  --set strategy.rollingUpdate.maxUnavailable=2 \
  --set strategy.rollingUpdate.maxSurge=3
```

---

## ⚙️ Configuration Examples

### Environment-Specific Deployments
```bash
# Staging environment
helm install myapp-staging ./rolling-chart \
  --set image.tag=v2.0.0-rc1 \
  --set replicaCount=2 \
  --set resources.requests.cpu=100m

# Production environment  
helm install myapp-prod ./rolling-chart \
  --set image.tag=v2.0.0 \
  --set replicaCount=6 \
  --set resources.requests.cpu=500m \
  --set autoscaling.enabled=true
```

### Custom Values File
```bash
# Create custom values
cat > production-values.yaml << EOF
replicaCount: 8
image:
  tag: v2.0.0
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
autoscaling:
  enabled: true
  minReplicas: 4
  maxReplicas: 20
EOF

# Deploy with custom values
helm install myapp ./rolling-chart -f production-values.yaml
```

---

## 🔍 Troubleshooting

### Chart Issues
```bash
# Validate chart structure
helm lint ./big-bang-chart
helm lint ./rolling-chart

# Debug template rendering
helm template myapp ./rolling-chart --debug

# Check values
helm get values myapp
```

### Deployment Issues
```bash
# Check deployment status
helm status myapp

# View deployment events
kubectl describe deployment myapp-rolling-app

# Check pod logs
kubectl logs -l app.kubernetes.io/name=myapp --tail=100
```

### Health Check Failures
```bash
# Check readiness/liveness probes
kubectl describe pods -l app.kubernetes.io/name=myapp

# Test health endpoints manually
kubectl port-forward svc/myapp 8080:80
curl http://localhost:8080/health
```

---

## 📊 Monitoring Integration

### Prometheus Metrics
Both charts include ServiceMonitor configuration:
```bash
# Enable monitoring
helm upgrade myapp ./rolling-chart \
  --set monitoring.enabled=true \
  --set monitoring.serviceMonitor.enabled=true
```

### Grafana Dashboards
```bash
# Import deployment metrics dashboard
kubectl apply -f monitoring/grafana-dashboard.yaml
```

---

## 🛡️ Security Considerations

### Image Security
```bash
# Use specific image tags (never :latest in production)
helm install myapp ./rolling-chart \
  --set image.tag=v2.0.0-sha256:abc123...

# Enable security context
helm install myapp ./rolling-chart \
  --set securityContext.runAsNonRoot=true \
  --set securityContext.runAsUser=1000
```

### Network Policies
```bash
# Deploy with network restrictions
helm install myapp ./rolling-chart \
  --set networkPolicy.enabled=true
```

---

## 🧪 Testing

### Local Testing with Minikube
```bash
# Start minikube
minikube start

# Deploy for testing
helm install test-app ./big-bang-chart \
  --set image.repository=nginx \
  --set image.tag=latest

# Access application
minikube service test-app-big-bang-app
```

### Automated Testing
```bash
# Test deployment with Helm test hooks
helm test myapp

# Integration testing
kubectl run test-pod --image=curlimages/curl --rm -it -- \
  curl http://myapp/health
```

---

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Production Best Practices](../../patterns/)

---

## 🆘 Emergency Procedures

### Quick Rollback
```bash
# Immediate rollback (Rolling)
kubectl rollout undo deployment/myapp-rolling-app

# Immediate rollback (Big Bang)
helm rollback myapp $(helm history myapp | tail -2 | head -1 | awk '{print $1}')
```

### Emergency Scale Down
```bash
# Scale to zero (emergency stop)
kubectl scale deployment myapp-rolling-app --replicas=0

# Scale back up
kubectl scale deployment myapp-rolling-app --replicas=6
```