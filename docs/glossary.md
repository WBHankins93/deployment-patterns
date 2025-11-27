# 📖 Deployment Patterns Glossary

A comprehensive glossary of terms related to deployment patterns and DevOps practices.

---

## A

**A/B Testing**
A deployment pattern where different versions are shown to different user segments simultaneously to compare performance and make data-driven decisions.

**Active Environment**
The environment currently serving production traffic (e.g., Blue in Blue-Green deployment).

**Alert**
A notification triggered when a metric crosses a threshold or an event occurs.

**Artifact**
A deployable package containing application code, dependencies, and configuration.

**Autoscaling**
Automatically adjusting the number of application instances based on demand.

---

## B

**Baseline**
The current production version used as a reference point in Canary or A/B Testing deployments.

**Big Bang Deployment**
A deployment strategy where all instances are updated simultaneously, causing downtime.

**Blue-Green Deployment**
A deployment pattern using two identical environments (Blue and Green), switching traffic between them for instant rollback.

**Build**
The process of compiling source code into executable artifacts.

**Burn-in Period**
The time a deployment runs before being considered stable.

---

## C

**Canary Deployment**
A deployment pattern that gradually rolls out changes to a small subset of users before full deployment.

**CI/CD**
Continuous Integration/Continuous Deployment - automated processes for building, testing, and deploying code.

**ConfigMap**
A Kubernetes resource for storing configuration data separate from application code.

**Container**
A lightweight, portable unit containing an application and its dependencies.

**Crash Loop**
When a container repeatedly starts and crashes, indicating a critical issue.

---

## D

**Deployment**
The process of releasing new code to production or staging environments.

**Deployment Pattern**
A strategy for updating applications in production (e.g., Rolling, Blue-Green, Canary).

**Downtime**
Period when a service is unavailable to users.

**Docker**
A platform for containerizing applications.

**Dry Run**
Simulating a deployment without actually executing it.

---

## E

**Environment**
A deployment target (e.g., development, staging, production).

**Error Rate**
The percentage of requests that result in errors (4xx or 5xx status codes).

**Exponential Backoff**
Gradually increasing wait time between retry attempts.

---

## F

**Feature Flag**
A technique to enable/disable features at runtime without redeployment.

**Full Rollout**
Deploying a new version to 100% of users or instances.

---

## G

**Green Environment**
The new environment in Blue-Green deployment, tested before receiving traffic.

**Graceful Shutdown**
Allowing in-flight requests to complete before terminating a service.

---

## H

**Health Check**
An endpoint or probe that verifies if a service is running correctly.

**Helm**
A package manager for Kubernetes applications.

**Horizontal Pod Autoscaler (HPA)**
Kubernetes feature that automatically scales pods based on metrics.

**Hotfix**
An urgent fix deployed outside the normal release cycle.

---

## I

**Idempotent**
An operation that produces the same result regardless of how many times it's executed.

**Immutable Deployment**
Deploying by creating new instances rather than modifying existing ones.

**Infrastructure as Code (IaC)**
Managing infrastructure through code and version control.

**Ingress**
Kubernetes resource for managing external access to services.

**Instance**
A single running copy of an application.

---

## K

**Kubernetes (K8s)**
Container orchestration platform for automating deployment, scaling, and management.

---

## L

**Liveness Probe**
A health check that determines if a container should be restarted.

**Load Balancer**
A service that distributes traffic across multiple instances.

**Load Testing**
Testing system behavior under expected load conditions.

---

## M

**Maintenance Window**
A scheduled period for planned deployments or maintenance.

**Mean Time to Deploy (MTTD)**
Average time from code commit to production deployment.

**Mean Time to Recovery (MTTR)**
Average time to restore service after a failure.

**Metrics**
Quantitative measurements of system behavior (e.g., response time, error rate).

**Mirroring**
Copying traffic to a shadow environment without affecting users (Shadow Deployment).

**Mixed Version State**
When different instances are running different versions simultaneously.

---

## N

**Namespace**
A Kubernetes mechanism for organizing resources and providing isolation.

**Node**
A worker machine in Kubernetes that runs containers.

---

## O

**Observability**
The ability to understand system behavior through logs, metrics, and traces.

**Orchestration**
Automated management of containerized applications.

---

## P

**Pod**
The smallest deployable unit in Kubernetes, containing one or more containers.

**Pod Disruption Budget (PDB)**
Kubernetes policy limiting disruptions during voluntary operations.

**Production**
The live environment serving real users.

**Prometheus**
Open-source monitoring and alerting toolkit.

---

## Q

**Quorum**
The minimum number of healthy instances required for a service to operate.

---

## R

**Readiness Probe**
A health check that determines if a container is ready to receive traffic.

**Replica**
A copy of an application instance.

**ReplicaSet**
Kubernetes resource that maintains a set of identical pod replicas.

**Rollback**
Reverting to a previous version after a failed deployment.

**Rolling Deployment**
Gradually replacing instances with new versions, ensuring zero downtime.

**Rollout**
The process of deploying a new version across all instances.

---

## S

**Service**
A Kubernetes abstraction that provides stable network access to pods.

**Service Mesh**
Infrastructure layer for managing service-to-service communication (e.g., Istio).

**Shadow Deployment**
A pattern where a new version receives mirrored traffic without affecting users.

**Smoke Test**
Basic tests run immediately after deployment to verify critical functionality.

**Staging**
An environment that mirrors production for final testing before deployment.

**Stateless**
An application that doesn't store session data, making it easier to scale and deploy.

---

## T

**Tag**
A label identifying a specific version of a container image (e.g., `v1.0.0`).

**Traffic Splitting**
Distributing requests across multiple versions (used in Canary and A/B Testing).

**Troubleshooting**
The process of diagnosing and resolving deployment issues.

---

## U

**Uptime**
The percentage of time a service is available and operational.

**User Segmentation**
Dividing users into groups for targeted deployments (Canary, A/B Testing).

---

## V

**Variant**
A different version in A/B Testing (Variant A vs Variant B).

**Version**
A specific release of application code (e.g., v1.0.0, v2.0.0).

**VirtualService**
Istio resource for configuring traffic routing and splitting.

---

## W

**Warm-up**
Gradually increasing traffic to a newly deployed instance.

**Workload**
A collection of pods running an application.

---

## Z

**Zero-Downtime Deployment**
A deployment strategy that maintains service availability throughout the process.

---

## Acronyms

**API** - Application Programming Interface  
**AWS** - Amazon Web Services  
**CDN** - Content Delivery Network  
**CI** - Continuous Integration  
**CD** - Continuous Deployment/Delivery  
**DNS** - Domain Name System  
**HPA** - Horizontal Pod Autoscaler  
**HTTP** - Hypertext Transfer Protocol  
**HTTPS** - HTTP Secure  
**IaC** - Infrastructure as Code  
**K8s** - Kubernetes (K + 8 letters + s)  
**LB** - Load Balancer  
**MTTD** - Mean Time to Deploy  
**MTTR** - Mean Time to Recovery  
**PDB** - Pod Disruption Budget  
**RBAC** - Role-Based Access Control  
**RPS** - Requests Per Second  
**SLA** - Service Level Agreement  
**SLO** - Service Level Objective  
**SLI** - Service Level Indicator  
**SRE** - Site Reliability Engineering  
**TLS** - Transport Layer Security  
**UI** - User Interface  
**URL** - Uniform Resource Locator  

---

## Pattern-Specific Terms

### Big Bang
- **Recreate Strategy**: Kubernetes deployment strategy that terminates all pods before creating new ones.

### Rolling
- **Batch**: A group of instances updated together in a rolling deployment.
- **Max Unavailable**: Maximum number of pods that can be unavailable during update.
- **Max Surge**: Maximum number of pods that can be created above desired count.

### Blue-Green
- **Blue Environment**: Current production environment.
- **Green Environment**: New version environment, tested before traffic switch.
- **Traffic Switch**: Changing load balancer to route traffic to new environment.

### Canary
- **Canary Percentage**: Percentage of traffic routed to the new version.
- **Promotion**: Increasing canary traffic percentage or completing rollout.
- **Baseline**: The current production version used for comparison.

### Shadow
- **Traffic Mirroring**: Copying production traffic to shadow environment.
- **Shadow Instance**: Instance receiving mirrored traffic but not serving users.

### A/B Testing
- **Control Group**: Users seeing the current version (Variant A).
- **Test Group**: Users seeing the new version (Variant B).
- **Statistical Significance**: Confidence that results are not due to chance.
- **Conversion Rate**: Percentage of users completing a desired action.

---

## Related Concepts

**DevOps**: Culture and practices combining development and operations.

**SRE**: Site Reliability Engineering - discipline for reliable systems.

**GitOps**: Using Git as the single source of truth for infrastructure and deployments.

**Infrastructure as Code**: Managing infrastructure through code.

**Microservices**: Architecture pattern using small, independent services.

**Monolith**: Single, unified application architecture.

---

## 📚 Learn More

- **[Getting Started Guide](getting-started.md)** - Beginner's tutorial
- **[Decision Guide](decision-guide.md)** - Pattern selection
- **[Best Practices](best-practices.md)** - Deployment best practices

---

*This glossary is a living document. Terms may be added or updated as the field evolves.*

