## 📄 Rolling Deployment ✅

### 🔄 What It Is
**Rolling Deployment** gradually replaces instances of the old version of your application with the new one, in **batches**. It avoids downtime by updating only a subset of servers at a time.

Most cloud platforms and orchestrators like Kubernetes support this natively.

---

### ✅ When to Use It
- Production environments that require high availability
- Systems where gradual rollout is safer
- When Big Bang is too risky but Blue-Green is overkill

---

### 📊 Pros
- ✅ Minimal to zero downtime
- ✅ Lower risk during deploy
- ✅ Built-in support in tools like K8s, ECS, etc.

---

### ❌ Cons
- ❌ Rollbacks mid-way can be complex (mixed state)
- ❌ Longer total deploy time
- ❌ Requires good health checks to abort on failure

---

### 🛠 Example CI/CD Snippet
```yaml
# GitHub Actions: Rolling Deployment
- name: Deploy to batch of servers
  run: ./scripts/rolling-batch-deploy.sh
```
<!-- END CODE BLOCK -->

🔗 **See full example**: [`rolling-deploy.yml`](examples/github-actions/rolling-deploy.yml)  
📂 **Deploy script reference**: [`rolling-batch-deploy.sh`](scripts/rolling-batch-deploy.sh)

---

### 💡 Real-World Example
We used rolling deployments at a previous startup to roll out updates to our Kubernetes cluster. Each batch deployed to 2 pods at a time. If the error rate spiked during health checks, the rollout automatically paused and alerted the on-call engineer.

This setup gave us the confidence to deploy during the day instead of after-hours.

---

### ⚠️ Gotchas to Watch For
- 🧩 Misconfigured health checks can silently let broken code through
- 🔙 Rollback logic must be clear if errors surface mid-deploy
- 🧠 Observability is crucial — dashboards and alerts must be in place

---

### 🧪 Validation Strategy
- ✅ Per-batch smoke tests
- ✅ Monitor logs and 500s during each step
- ✅ Alert on latency or availability drops

---

### 🧠 TL;DR
Rolling deployments are **ideal for high-uptime systems** where slow, safe rollout is preferred over instant switchovers.
Use when:
- You have automated monitoring in place
- You want to minimize user disruption
- You don’t need instant rollback

Avoid when:
- You can’t afford a mixed-version state
- You lack observability or batch health validation