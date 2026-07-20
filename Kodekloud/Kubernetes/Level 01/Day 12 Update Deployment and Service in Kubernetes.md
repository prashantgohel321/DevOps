# Kubernetes Level 01 – Day 12: Update Deployment and Service In-Place

This document explains how to modify existing Kubernetes resources without deleting and recreating them. The goal is to update a Service and a Deployment while maintaining application availability.

---

- [Kubernetes Level 01 – Day 12: Update Deployment and Service In-Place](#kubernetes-level-01--day-12-update-deployment-and-service-in-place)
  - [Objective](#objective)
- [Understanding In-Place Updates](#understanding-in-place-updates)
- [Step 1: Update Service NodePort](#step-1-update-service-nodeport)
- [Step 2: Scale Deployment Replicas](#step-2-scale-deployment-replicas)
- [Step 3: Update Deployment Image](#step-3-update-deployment-image)
- [Step 4: Verification](#step-4-verification)
  - [Verify Service Port](#verify-service-port)
  - [Verify Deployment Replicas](#verify-deployment-replicas)
  - [Verify Image Update](#verify-image-update)
- [What Happens Internally](#what-happens-internally)
    - [Service Update](#service-update)
    - [Scaling Replicas](#scaling-replicas)
    - [Rolling Update](#rolling-update)
- [Key Outcome](#key-outcome)

<br>
<br>

## Objective

Apply the following updates:

* **Service:** `nginx-service`
* **Deployment:** `nginx-deployment`

Required changes:

1. Change Service `nodePort` from `30008` to `32165`
2. Increase Deployment replicas from `1` to `5`
3. Update container image from `nginx:1.19` to `nginx:latest`

All changes must be performed in-place.

---

<br>
<br>

# Understanding In-Place Updates

Kubernetes is built around declarative state reconciliation. Instead of deleting resources and recreating them, you modify their specification. The control plane then adjusts the running cluster to match the new desired state.

This prevents downtime and preserves networking configurations.

---

<br>
<br>

# Step 1: Update Service NodePort

To modify the NodePort of an existing service:

```bash
kubectl edit service nginx-service
```

This opens the Service configuration in your default editor.

Locate:

```yaml
ports:
  - port: 80
    nodePort: 30008
```

Change it to:

```yaml
nodePort: 32165
```

Save and exit.

Kubernetes updates the Service configuration immediately.

Alternative method using patch:

```bash
kubectl patch svc nginx-service \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32165}]'
```

---

<br>
<br>

# Step 2: Scale Deployment Replicas

Increase the number of replicas from 1 to 5:

```bash
kubectl scale deployment nginx-deployment --replicas=5
```

The Deployment controller will:

1. Create additional Pods
2. Wait for them to become Ready
3. Ensure total desired count equals 5

---

<br>
<br>

# Step 3: Update Deployment Image

Update the container image and trigger a rolling update.

```bash
kubectl set image deployment/nginx-deployment nginx-container=nginx:latest
```

This command modifies the Deployment template.

When the Pod template changes, Kubernetes automatically:

1. Creates a new ReplicaSet
2. Gradually spins up new Pods
3. Terminates old Pods only after new ones are ready

This is the Rolling Update mechanism.

---

<br>
<br>

# Step 4: Verification

## Verify Service Port

```bash
kubectl get service nginx-service

# OUTPUT

thor@jumphost ~$ kubectl get service nginx-service
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.96.158.122   <none>        80:32165/TCP   9m5s
```

The `PORT(S)` column should show:

```text
80:32165/TCP
```

---

<br>
<br>

## Verify Deployment Replicas

```bash
kubectl get deployments

# OUTPUT

thor@jumphost ~$ kubectl get deployments.apps 
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   5/5     5            5           9m20s
```

Expected:

```text
5/5 READY
```

Check Pods:

```bash
kubectl get pods

# OUTPUT

thor@jumphost ~$ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-854ff588b7-4gx9d   1/1     Running   0          34s
nginx-deployment-854ff588b7-68jzr   1/1     Running   0          25s
nginx-deployment-854ff588b7-7cxmg   1/1     Running   0          34s
nginx-deployment-854ff588b7-brt6l   1/1     Running   0          25s
nginx-deployment-854ff588b7-mt8t4   1/1     Running   0          34s
```

Five Pods should be running.

---

<br>
<br>

## Verify Image Update

```bash
kubectl describe deployment nginx-deployment | grep Image

# OUTPUT
thor@jumphost ~$ kubectl describe deployment nginx-deployment | grep Image
    Image:         nginx:latest
```

Expected:

```text
Image: nginx:latest
```

---

<br>
<br>

# What Happens Internally

### Service Update

Changing the NodePort updates kube-proxy rules (iptables/IPVS). The ClusterIP remains unchanged, so internal traffic is unaffected.

### Scaling Replicas

The Deployment controller adjusts the ReplicaSet’s desired count.

Pods are created until the new replica count is reached.

### Rolling Update

When the image changes:

1. A new ReplicaSet is created
2. Pods with the new image start
3. Old Pods are gradually terminated

This prevents downtime.

---

<br>
<br>

# Key Outcome

The `nginx-service` and `nginx-deployment` have been updated successfully without deletion. The application now:

* Listens on NodePort `32165`
* Runs 5 replicas
* Uses image `nginx:latest`

All updates were applied in-place, maintaining continuous availability.
