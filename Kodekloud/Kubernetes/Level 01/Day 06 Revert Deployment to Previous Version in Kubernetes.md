# Kubernetes Level 01 – Day 06: Revert Deployment to Previous Version

This document explains how to revert a Kubernetes Deployment to its previous stable revision. The scenario assumes that a newly released version introduced a production issue, and an immediate rollback is required to restore service stability.

---

<br>
<br>

- [Kubernetes Level 01 – Day 06: Revert Deployment to Previous Version](#kubernetes-level-01--day-06-revert-deployment-to-previous-version)
  - [Objective](#objective)
- [Understanding the Situation](#understanding-the-situation)
- [Step 1: Check Deployment History](#step-1-check-deployment-history)
- [Step 2: Perform the Rollback](#step-2-perform-the-rollback)
- [Step 3: Verify Rollout Status](#step-3-verify-rollout-status)
- [What Actually Happens Internally](#what-actually-happens-internally)
- [Why Rollbacks Are Critical in Production](#why-rollbacks-are-critical-in-production)
- [Key Outcome](#key-outcome)

<br>
<br>

## Objective

Revert the Deployment named:

* **Deployment:** `nginx-deployment`
* **Action:** Roll back to the immediately previous revision

---

<br>
<br>

# Understanding the Situation

In Kubernetes, a Deployment manages Pods using ReplicaSets. Each time you update a Deployment (for example, changing a container image version), Kubernetes creates a new ReplicaSet and scales it up while scaling down the previous one.

Importantly, Kubernetes does not delete the old ReplicaSet. It keeps it as part of the rollout history. This stored history is what makes rollback possible.

If the new version causes issues (application crash, configuration error, performance regression), we can instruct Kubernetes to reapply the previous ReplicaSet configuration.

---

<br>
<br>

# Step 1: Check Deployment History

Before performing a rollback, verify available revisions.

```bash
kubectl rollout history deployment nginx-deployment
```

Example output:

```text
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

* Revision 2 → Current (buggy version)
* Revision 1 → Previous stable version

This confirms that Revision 1 is available for rollback.

---

<br>
<br>

# Step 2: Perform the Rollback

To revert to the previous revision:

```bash
kubectl rollout undo deployment nginx-deployment
```

Expected output:

```text
deployment.apps/nginx-deployment rolled back
```

This command tells Kubernetes to restore the configuration from the previous ReplicaSet.

If you need to roll back to a specific revision instead of just "previous":

```bash
kubectl rollout undo deployment nginx-deployment --to-revision=1
```

---

<br>
<br>

# Step 3: Verify Rollout Status

Monitor the rollback process:

```bash
kubectl rollout status deployment/nginx-deployment
```

Expected output:

```text
deployment "nginx-deployment" successfully rolled out
```

This confirms that the old ReplicaSet has been scaled up and is now serving traffic.

You can verify the history again:

```bash
kubectl rollout history deployment nginx-deployment
```

You may see a new revision number (for example, Revision 3). This represents the system reapplying the previous configuration.

---

<br>
<br>

# What Actually Happens Internally

When a Deployment is updated:

1. Kubernetes creates a new ReplicaSet.
2. It gradually scales up the new ReplicaSet.
3. It scales down the old ReplicaSet.

When `rollout undo` is executed:

1. Kubernetes identifies the previously active ReplicaSet.
2. It scales that ReplicaSet back up.
3. It scales down the faulty ReplicaSet.

This process follows the same rolling update strategy defined in the Deployment (such as maxUnavailable and maxSurge). Because of this, rollback is typically zero-downtime.

---

<br>
<br>

# Why Rollbacks Are Critical in Production

Rollbacks allow teams to:

* Recover quickly from failed deployments
* Minimize production downtime
* Avoid rebuilding or redeploying previous container images manually
* Maintain service reliability during rapid release cycles

Instead of editing YAML files again or pushing older images manually, Kubernetes handles the reversion automatically using stored rollout history.

---

<br>
<br>

# Key Outcome

The Deployment `nginx-deployment` has been successfully reverted to its previous stable revision. The application is now running using a known working configuration, restoring production stability without downtime.
