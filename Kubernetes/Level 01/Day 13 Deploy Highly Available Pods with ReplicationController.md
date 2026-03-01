# Kubernetes Level 01 – Day 13: Deploy Highly Available Pods with ReplicationController

This document explains how to deploy a ReplicationController in Kubernetes to maintain a fixed number of running Pods. The goal is to ensure high availability by automatically recreating Pods if they fail or are deleted.

---

- [Kubernetes Level 01 – Day 13: Deploy Highly Available Pods with ReplicationController](#kubernetes-level-01--day-13-deploy-highly-available-pods-with-replicationcontroller)
  - [Objective](#objective)
- [Understanding the Role of a ReplicationController](#understanding-the-role-of-a-replicationcontroller)
- [Step 1: Create the YAML Manifest](#step-1-create-the-yaml-manifest)
  - [Manifest Content](#manifest-content)
- [Key Configuration Points](#key-configuration-points)
- [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
- [Step 3: Verification](#step-3-verification)
  - [Check ReplicationController Status](#check-replicationcontroller-status)
  - [Check Managed Pods](#check-managed-pods)
  - [Describe the ReplicationController](#describe-the-replicationcontroller)
- [Internal Working Mechanism](#internal-working-mechanism)
- [ReplicationController vs ReplicaSet](#replicationcontroller-vs-replicaset)
- [Key Outcome](#key-outcome)



<br>
<br>

## Objective

Provision a ReplicationController with the following configuration:

* **Resource Kind:** `ReplicationController`
* **Name:** `nginx-replicationcontroller`
* **Image:** `nginx:latest`
* **Container Name:** `nginx-container`
* **Replicas:** `3`
* **Labels:**

  * `app: nginx_app`
  * `type: front-end`

---

<br>
<br>

# Understanding the Role of a ReplicationController

A ReplicationController (RC) ensures that a specific number of Pod replicas are running at all times.

It continuously checks:

* Desired state → `spec.replicas`
* Actual state → Number of Pods matching the selector

If the number of running Pods drops below the desired count, it creates new ones. If there are too many, it terminates extras.

This provides a self-healing mechanism in case of crashes or node failures.

---

<br>
<br>

# Step 1: Create the YAML Manifest

Create a file for the ReplicationController definition:

```bash
vi rc.yaml
```

## Manifest Content

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-replicationcontroller
  labels:
    app: nginx_app
    type: front-end
spec:
  replicas: 3
  selector:
    app: nginx_app
    type: front-end
  template:
    metadata:
      labels:
        app: nginx_app
        type: front-end
    spec:
      containers:
      - name: nginx-container
        image: nginx:latest
```

---

<br>
<br>

# Key Configuration Points

* `apiVersion: v1` → ReplicationController belongs to the core API group.
* `spec.replicas` → Defines desired Pod count.
* `spec.selector` → Determines which Pods the RC manages.
* `spec.template.metadata.labels` → Must match the selector exactly.

If selector and template labels do not match, the controller will not manage its own Pods correctly.

---

<br>
<br>

# Step 2: Apply the Configuration

Create the ReplicationController in the cluster:

```bash
kubectl apply -f rc.yaml
```

Expected output:

```text
replicationcontroller/nginx-replicationcontroller created
```

Once created, Kubernetes immediately schedules three Pods.

---

<br>
<br>

# Step 3: Verification

## Check ReplicationController Status

```bash
kubectl get rc

# OUTPUT
thor@jumphost ~$ kubectl get rc
NAME                          DESIRED   CURRENT   READY   AGE
nginx-replicationcontroller   3         3         3       11s
```

Expected columns:

* DESIRED → 3
* CURRENT → 3
* READY → 3

---

<br>
<br>

## Check Managed Pods

```bash
kubectl get pods -l app=nginx_app

# OUTPUT

thor@jumphost ~$ kubectl get pods -l app=nginx_app
NAME                                READY   STATUS    RESTARTS   AGE
nginx-replicationcontroller-8zxvs   1/1     Running   0          27s
nginx-replicationcontroller-mdp7d   1/1     Running   0          27s
nginx-replicationcontroller-mpw87   1/1     Running   0          27s
```

You should see three Pods in the `Running` state.

---

<br>
<br>

## Describe the ReplicationController

```bash
kubectl describe rc nginx-replicationcontroller

# OUTPUT

thor@jumphost ~$ kubectl describe rc nginx-replicationcontroller 
Name:         nginx-replicationcontroller
Namespace:    default
Selector:     app=nginx_app,type=front-end
Labels:       app=nginx_app
              type=front-end
Annotations:  <none>
Replicas:     3 current / 3 desired
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=nginx_app
           type=front-end
  Containers:
   nginx-container:
    Image:         nginx:latest
    Port:          <none>
    Host Port:     <none>
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Events:
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  44s   replication-controller  Created pod: nginx-replicationcontroller-mpw87
  Normal  SuccessfulCreate  44s   replication-controller  Created pod: nginx-replicationcontroller-8zxvs
  Normal  SuccessfulCreate  44s   replication-controller  Created pod: nginx-replicationcontroller-mdp7d
```

Verify:

* Selector matches `app=nginx_app,type=front-end`
* Container name is `nginx-container`
* Image is `nginx:latest`

---

<br>
<br>

# Internal Working Mechanism

The ReplicationController operates through reconciliation:

1. It monitors Pod count matching its selector.
2. If a Pod is deleted manually → It creates a replacement.
3. If a Node fails → It recreates lost Pods on another Node.

This ensures availability even during infrastructure instability.

---

<br>
<br>

# ReplicationController vs ReplicaSet

ReplicationController was the original controller for maintaining replica counts.

However, ReplicaSets later replaced it for most use cases.

Key differences:

* ReplicationController supports only equality-based selectors.
* ReplicaSet supports set-based selectors (more flexible).
* Deployments manage ReplicaSets and provide rolling updates and rollbacks.

In modern Kubernetes, Deployments are preferred for production workloads.

ReplicationControllers are primarily encountered in legacy clusters or certification tasks.

---

<br>
<br>

# Key Outcome

The `nginx-replicationcontroller` is successfully deployed with 3 running Pods. The controller now guarantees high availability by maintaining the desired replica count automatically.
