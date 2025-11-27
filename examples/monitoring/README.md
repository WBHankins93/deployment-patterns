# 📊 Monitoring Examples

This directory contains monitoring configurations and examples for deployment patterns.

## 📁 Contents

- **`prometheus-alerts.yaml`** - Prometheus alert rules for all deployment patterns
- **`grafana-dashboards/`** - Grafana dashboard JSON exports
  - `deployment-overview.json` - General deployment monitoring dashboard

## 🚀 Quick Start

### Prometheus Alerts

```bash
# Create ConfigMap in Kubernetes
kubectl create configmap prometheus-alerts \
  --from-file=prometheus-alerts.yaml \
  -n monitoring

# Or add to Prometheus configuration
# In prometheus.yml:
rule_files:
  - "prometheus-alerts.yaml"
```

### Grafana Dashboards

1. **Import Dashboard:**
   - Open Grafana
   - Go to Dashboards → Import
   - Upload `grafana-dashboards/deployment-overview.json`
   - Select your Prometheus data source

2. **Customize:**
   - Adjust panel queries for your metrics
   - Update label selectors to match your services
   - Add custom panels as needed

## 📊 Alert Categories

### General Deployment Alerts
- `DeploymentFailure` - Deployment has failed
- `DeploymentStuck` - Deployment stuck for >10 minutes
- `HighErrorRateAfterDeployment` - Error rate >5% after deploy
- `PodCrashLoop` - Pods restarting repeatedly

### Pattern-Specific Alerts

#### Big Bang
- `BigBangServiceDown` - Complete service outage
- `BigBangSlowRecovery` - Recovery taking >5 minutes

#### Rolling
- `RollingDeploymentStuck` - Rollout stuck
- `RollingDeploymentMixedVersions` - Mixed versions >15 minutes
- `RollingDeploymentHighErrorRate` - Error rate >10% during rollout

#### Blue-Green
- `BlueGreenEnvironmentUnhealthy` - Environment <80% healthy
- `BlueGreenTrafficSwitchFailure` - Traffic switch incomplete

#### Canary
- `CanaryHighErrorRate` - Canary error rate 2x baseline
- `CanaryPerformanceDegradation` - Canary latency 2x baseline
- `CanaryTrafficImbalance` - Traffic distribution incorrect

### Infrastructure Alerts
- `DeploymentResourceExhaustion` - Cluster resources >90%
- `ImagePullFailure` - Cannot pull container images
- `HealthCheckFailure` - Pod health checks failing

### Post-Deployment Validation
- `PostDeploymentRegression` - Performance regression detected
- `DeploymentSuccessRateLow` - Success rate <95% after deploy

## 🔧 Customization

### Adjusting Thresholds

Edit `prometheus-alerts.yaml` to customize:
- Alert durations (`for: 5m`)
- Error rate thresholds (`> 0.05`)
- Time windows for comparisons

### Adding Custom Metrics

1. **Define Recording Rules:**
   ```yaml
   - record: deployment:custom_metric
     expr: your_custom_query_here
   ```

2. **Create Alert:**
   ```yaml
   - alert: CustomMetricAlert
     expr: deployment:custom_metric > threshold
   ```

## 📈 Dashboard Panels

### Deployment Overview Dashboard

1. **Deployment Status** - Replica availability percentage
2. **Error Rate** - 5xx error rate over time
3. **Request Rate** - Requests per second by status code
4. **Latency** - P50, P95, P99 latency percentiles
5. **Pod Status** - Pod distribution by version
6. **Resource Utilization** - CPU and memory usage

## 🎯 Integration with Deployment Scripts

Deployment scripts can add annotations to mark deployment events:

```bash
# In deployment script
kubectl annotate deployment myapp \
  deployment.kubernetes.io/deployment-time="$(date +%s)" \
  deployment.kubernetes.io/version="$VERSION"
```

These annotations can be used in Grafana to mark deployment events on graphs.

## 📚 Additional Resources

- [Prometheus Alerting Documentation](https://prometheus.io/docs/alerting/latest/overview/)
- [Grafana Dashboard Documentation](https://grafana.com/docs/grafana/latest/dashboards/)
- [Monitoring Guide](../../docs/monitoring-guide.md)

---

*For troubleshooting deployment issues, see [Troubleshooting Guide](../../docs/troubleshooting.md)*

