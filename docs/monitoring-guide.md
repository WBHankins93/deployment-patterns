# 📊 Deployment Monitoring & Observability Guide

Comprehensive guide to monitoring and observability best practices for deployment patterns.

## 🎯 Overview

Effective monitoring is critical for successful deployments. This guide covers:
- **Pre-deployment monitoring** - Baseline metrics and health checks
- **During-deployment monitoring** - Real-time tracking and alerting
- **Post-deployment monitoring** - Validation and success metrics

---

## 📈 Key Metrics to Monitor

### Application Metrics

#### Health & Availability
- **Uptime**: Service availability percentage
- **Health Check Status**: Success/failure rates of health endpoints
- **Response Time**: P50, P95, P99 latency percentiles
- **Error Rate**: 4xx and 5xx HTTP status codes per second

#### Performance Metrics
- **Request Rate**: Requests per second (RPS)
- **Throughput**: Successful requests per second
- **Resource Utilization**: CPU, memory, disk I/O
- **Database Connections**: Active connections, connection pool usage

#### Business Metrics
- **Transaction Success Rate**: Critical business operations
- **User Activity**: Active users, session duration
- **Feature Adoption**: New feature usage rates

### Infrastructure Metrics

#### Container/Pod Metrics
- **Pod Status**: Running, pending, failed, crash loop
- **Container Restarts**: Restart count and frequency
- **Resource Limits**: CPU/memory throttling events

#### Network Metrics
- **Traffic Distribution**: Requests per instance/pod
- **Connection Counts**: Active connections per service
- **Network Errors**: Connection timeouts, DNS failures

---

## 🔍 Monitoring by Deployment Pattern

### Big Bang Deployment

**Critical Metrics:**
- Service downtime duration
- Recovery time after deployment
- Error spike detection (immediate)
- Database migration status

**Monitoring Strategy:**
```yaml
# Pre-deployment
- Capture baseline metrics (5 minutes)
- Verify all health checks passing
- Check database connectivity

# During deployment
- Monitor for complete service outage
- Track deployment duration
- Watch for immediate error spikes

# Post-deployment
- Validate service restoration (< 5 minutes)
- Monitor error rates for 15 minutes
- Check all critical endpoints
```

### Rolling Deployment

**Critical Metrics:**
- Pod readiness per batch
- Error rate per batch
- Traffic distribution across versions
- Rollout progress percentage

**Monitoring Strategy:**
```yaml
# Pre-deployment
- Verify all pods healthy
- Check load balancer distribution
- Baseline error rates

# During deployment
- Monitor each batch independently
- Track mixed-version state metrics
- Watch for gradual error increases
- Monitor resource capacity

# Post-deployment
- Verify all pods on new version
- Check for lingering old-version pods
- Validate traffic distribution
```

### Blue-Green Deployment

**Critical Metrics:**
- Environment health (both Blue and Green)
- Traffic switch success rate
- Resource utilization in both environments
- DNS/load balancer switch latency

**Monitoring Strategy:**
```yaml
# Pre-deployment
- Verify Green environment health
- Compare Green vs Blue baseline metrics
- Check resource availability

# During deployment
- Monitor Green environment under test traffic
- Track switchover duration
- Watch for traffic routing issues

# Post-deployment
- Monitor new active environment
- Keep old environment monitored (for rollback)
- Validate traffic routing
```

### Canary Deployment

**Critical Metrics:**
- Canary vs baseline comparison
- Error rate differential
- Performance differential (latency, throughput)
- User experience metrics

**Monitoring Strategy:**
```yaml
# Pre-deployment
- Establish baseline metrics
- Configure canary traffic percentage
- Set up comparison dashboards

# During deployment
- Compare canary metrics vs baseline
- Track error rate differences
- Monitor user experience impact
- Watch for performance degradation

# Post-deployment
- Validate full rollout metrics
- Compare final metrics to canary metrics
- Document any discrepancies
```

---

## 🚨 Alerting Strategy

### Critical Alerts (Immediate Response)

```yaml
# Service Down
- Condition: Health check failures > 50% for 1 minute
- Severity: Critical
- Action: Immediate rollback consideration

# Error Rate Spike
- Condition: Error rate > 5x baseline for 2 minutes
- Severity: Critical
- Action: Pause deployment, investigate

# Deployment Stuck
- Condition: Deployment progress unchanged for 10 minutes
- Severity: High
- Action: Investigate and potentially rollback
```

### Warning Alerts (Investigation Needed)

```yaml
# Elevated Error Rate
- Condition: Error rate > 2x baseline for 5 minutes
- Severity: Warning
- Action: Monitor closely, prepare rollback

# Performance Degradation
- Condition: P95 latency > 2x baseline for 5 minutes
- Severity: Warning
- Action: Investigate performance impact

# Resource Constraints
- Condition: CPU/Memory > 80% for 5 minutes
- Severity: Warning
- Action: Scale resources or pause deployment
```

### Informational Alerts

```yaml
# Deployment Started
- Condition: Deployment workflow initiated
- Severity: Info
- Action: Track in monitoring dashboard

# Deployment Completed
- Condition: All pods healthy on new version
- Severity: Info
- Action: Update deployment status
```

---

## 📊 Prometheus Configuration

### Recording Rules

```yaml
groups:
  - name: deployment_metrics
    interval: 30s
    rules:
      - record: deployment:error_rate:ratio
        expr: |
          rate(http_requests_total{code=~"5.."}[5m]) 
          / 
          rate(http_requests_total[5m])
      
      - record: deployment:latency_p95
        expr: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket[5m])
          )
      
      - record: deployment:success_rate
        expr: |
          rate(http_requests_total{code=~"2.."}[5m]) 
          / 
          rate(http_requests_total[5m])
```

### Alert Rules

See `examples/monitoring/prometheus-alerts.yaml` for complete alert configurations.

---

## 📈 Grafana Dashboards

### Deployment Overview Dashboard

**Key Panels:**
1. **Deployment Status** - Current deployment state and progress
2. **Error Rate Trend** - Error rate over time with deployment markers
3. **Request Rate** - Traffic volume with version breakdown
4. **Latency Distribution** - P50, P95, P99 latency
5. **Pod Status** - Pod health and version distribution
6. **Resource Utilization** - CPU, memory, network usage

### Pattern-Specific Dashboards

- **Big Bang**: Focus on downtime duration and recovery time
- **Rolling**: Batch-by-batch progress and mixed-version metrics
- **Blue-Green**: Side-by-side environment comparison
- **Canary**: Canary vs baseline comparison

See `examples/monitoring/grafana-dashboards/` for dashboard JSON exports.

---

## 🔧 Implementation Checklist

### Pre-Deployment
- [ ] Baseline metrics captured (5-15 minutes)
- [ ] Health checks verified
- [ ] Alerting rules tested
- [ ] Dashboard access confirmed
- [ ] On-call engineer notified

### During Deployment
- [ ] Real-time monitoring dashboard open
- [ ] Alert channels monitored
- [ ] Key metrics tracked per batch/environment
- [ ] Rollback triggers clearly defined

### Post-Deployment
- [ ] Metrics validated against baseline
- [ ] Error rates within acceptable range
- [ ] Performance metrics stable
- [ ] Deployment marked complete in monitoring system
- [ ] Post-deployment report generated

---

## 🛠️ Tools & Integrations

### Recommended Stack

**Metrics Collection:**
- Prometheus (metrics storage)
- Grafana (visualization)
- Datadog / New Relic (alternative SaaS)

**Logging:**
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Loki (Prometheus-native logging)
- CloudWatch Logs (AWS)

**Tracing:**
- Jaeger
- Zipkin
- OpenTelemetry

**Alerting:**
- Alertmanager (Prometheus)
- PagerDuty
- Slack / Microsoft Teams

### Integration Examples

See `examples/monitoring/` for:
- Prometheus alert configurations
- Grafana dashboard JSON files
- ServiceMonitor configurations for Kubernetes

---

## 📚 Best Practices

1. **Establish Baselines**: Always capture baseline metrics before deployment
2. **Set Clear Thresholds**: Define acceptable error rates and latency before deploying
3. **Monitor Differentials**: Compare new version metrics to baseline, not absolute values
4. **Automate Alerting**: Set up automated alerts for common failure patterns
5. **Dashboard First**: Create dashboards before you need them
6. **Document Runbooks**: Create runbooks for common alert scenarios
7. **Regular Reviews**: Review and tune alert thresholds based on historical data
8. **Test Alerts**: Regularly test alert delivery and response procedures

---

## 🎯 Success Criteria

A well-monitored deployment should provide:

✅ **Visibility**: Clear view of deployment progress and health  
✅ **Early Detection**: Issues detected before user impact  
✅ **Actionable Alerts**: Clear guidance on what to do when alerts fire  
✅ **Historical Context**: Ability to compare deployments over time  
✅ **Quick Rollback**: Metrics support fast decision-making for rollbacks  

---

## 📖 Additional Resources

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [SRE Monitoring Principles](https://sre.google/sre-book/monitoring-distributed-systems/)
- [CNCF Observability Landscape](https://landscape.cncf.io/card-mode?category=observability-and-analysis)

---

*This guide is part of the Deployment Patterns Guide. For pattern-specific monitoring details, see individual pattern documentation in `../patterns/`.*

