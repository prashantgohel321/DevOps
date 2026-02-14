# Kubernetes Level 01 Day 05: Performing Zero-Downtime Rolling Updates on a Deployment

This document explains how to upgrade an existing Deployment to a new container image version using Kubernetes’ rolling update strategy. The objective is to change the image used by `nginx-deployment` to `nginx:1.19` while ensuring continuous availability and avoiding downtime.

Rolling updates are not just about changing an image tag. They involve coordinated ReplicaSet transitions, readiness checks, and controlled scaling behavior managed automatically by the Deployment controller.

---

<br>
<br>

- [Kubernetes Level 01 Day 05: Performing Zero-Downtime Rolling Updates on a Deployment](#kubernetes-level-01-day-05-performing-zero-downtime-rolling-updates-on-a-deployment)
  - [Understanding the Situation Before Updating](#understanding-the-situation-before-updating)
  - [Step 1: Verify the Current State of the Deployment](#step-1-verify-the-current-state-of-the-deployment)
  - [Step 2: Identify the Container Name Inside the Deployment](#step-2-identify-the-container-name-inside-the-deployment)
  - [Step 3: Perform the Rolling Update](#step-3-perform-the-rolling-update)
  - [Step 4: Monitor the Rolling Update](#step-4-monitor-the-rolling-update)
  - [Verifying the New Image Is Active](#verifying-the-new-image-is-active)
  - [Internal Mechanics of Rolling Updates](#internal-mechanics-of-rolling-updates)
  - [Observing Revision History](#observing-revision-history)
  - [Performing a Rollback](#performing-a-rollback)
  - [What Happens If New Pods Fail](#what-happens-if-new-pods-fail)
  - [Final State After Completion](#final-state-after-completion)


<br>
<br>

## Understanding the Situation Before Updating

A Deployment manages a ReplicaSet, which manages Pods. When you modify the Pod template (for example, by changing the container image), Kubernetes does not modify existing Pods directly. Instead, it creates a new ReplicaSet derived from the updated template.

The old ReplicaSet represents the previous version. The new ReplicaSet represents the updated version. Kubernetes gradually shifts traffic by scaling one down and the other up.

---

<br>
<br>

## Step 1: Verify the Current State of the Deployment

Before updating, confirm that the Deployment exists and that its Pods are running.

```bash
kubectl get deployments
kubectl get pods
```

Check the current image in use:

```bash
kubectl describe deployment nginx-deployment | grep Image
```

This establishes a baseline before modification.

---

<br>
<br>

## Step 2: Identify the Container Name Inside the Deployment

The `kubectl set image` command requires the container name defined inside the Pod template.

```bash
kubectl describe deployment nginx-deployment
```

Under the `Pod Template` section, locate `Containers:` and note the container name. This may be `nginx` or another name specified when the Deployment was created.

The container name is important because a Deployment can technically manage multiple containers within one Pod.

---

<br>
<br>

## Step 3: Perform the Rolling Update

Update the image using the imperative method.

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.19
```

This command updates the Pod template. Kubernetes detects the template change and automatically performs a rolling update.

Alternatively, edit the Deployment directly:

```bash
kubectl edit deployment nginx-deployment
```

Change the image field under:

```
spec:
  template:
    spec:
      containers:
        - name: nginx
          image: nginx:1.19
```

Saving the file triggers the update process.

---

<br>
<br>

## Step 4: Monitor the Rolling Update

Track progress in real time.

```bash
kubectl rollout status deployment/nginx-deployment
```

Expected output upon completion:

```
deployment "nginx-deployment" successfully rolled out
```

Observe ReplicaSets during rollout:

```bash
kubectl get replicasets
```

You will see two ReplicaSets temporarily:

* One old (previous image)
* One new (nginx:1.19)

Watch Pods during the transition:

```bash
kubectl get pods -w
```

Pods with new template hashes will gradually replace old ones.

---

<br>
<br>

## Verifying the New Image Is Active

Confirm the image version:

```bash
kubectl describe deployment nginx-deployment | grep Image
```

Or inspect Pods directly:

```bash
kubectl get pods -o wide
kubectl describe pod <pod-name> | grep Image
```

All Pods should now reference `nginx:1.19`.

---

<br>
<br>

## Internal Mechanics of Rolling Updates

The default rolling update strategy is defined as:

* maxSurge: 25%
* maxUnavailable: 25%

These values mean Kubernetes may create up to 25% extra Pods above the desired replica count during update (surge capacity), and may allow up to 25% of Pods to be temporarily unavailable.

For example, if replicas = 4:

* Up to 5 Pods may run temporarily (surge)
* At least 3 remain available during transition

These parameters can be customized:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

Setting `maxUnavailable: 0` guarantees zero downtime at the cost of temporary extra resource usage.

---

<br>
<br>

## Observing Revision History

Each update creates a revision.

```bash
kubectl rollout history deployment/nginx-deployment
```

To inspect a specific revision:

```bash
kubectl rollout history deployment/nginx-deployment --revision=2
```

---

<br>
<br>

## Performing a Rollback

If the new version is unstable, revert to the previous revision.

```bash
kubectl rollout undo deployment/nginx-deployment
```

Kubernetes restores the previous ReplicaSet by updating the Deployment template again.

Monitor rollback:

```bash
kubectl rollout status deployment/nginx-deployment
```

---

<br>
<br>

## What Happens If New Pods Fail

If the new image fails readiness checks or crashes repeatedly, rollout pauses. You can inspect:

```bash
kubectl describe deployment nginx-deployment
kubectl get pods
```

If readiness probes were configured, Kubernetes waits until new Pods are marked Ready before scaling down old ones. Without readiness probes, traffic may shift prematurely.

---

<br>
<br>

## Final State After Completion

At the end of this task:

* The Deployment `nginx-deployment` uses image `nginx:1.19`
* A new ReplicaSet replaced the old one
* Pods were updated incrementally
* Availability was maintained during transition
* Revision history is preserved for rollback

Rolling updates demonstrate how Kubernetes handles controlled application upgrades without shutting down services, forming the basis for production-grade deployment strategies.
