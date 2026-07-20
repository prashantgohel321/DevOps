# Kubernetes Level 01 – Day 07: Deploy ReplicaSet in Kubernetes Cluster

This document explains how to deploy a ReplicaSet in a Kubernetes cluster to maintain multiple identical Pods. The goal is to ensure application availability by guaranteeing that a fixed number of Pods are always running.

---

<br>
<br>

- [Kubernetes Level 01 – Day 07: Deploy ReplicaSet in Kubernetes Cluster](#kubernetes-level-01--day-07-deploy-replicaset-in-kubernetes-cluster)
  - [Objective](#objective)
- [Understanding the Role of a ReplicaSet](#understanding-the-role-of-a-replicaset)
- [Step 1: Create the YAML Manifest](#step-1-create-the-yaml-manifest)
    - [Manifest Content](#manifest-content)
    - [Important Configuration Points](#important-configuration-points)
- [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
- [Step 3: Verification](#step-3-verification)
  - [Check ReplicaSet Status](#check-replicaset-status)
  - [Check Pods](#check-pods)
  - [Describe ReplicaSet](#describe-replicaset)
- [How ReplicaSet Works Internally](#how-replicaset-works-internally)
- [Selector and Label Relationship](#selector-and-label-relationship)
- [ReplicaSet vs Deployment](#replicaset-vs-deployment)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Deploy a ReplicaSet with the following configuration:

* **ReplicaSet Name:** `httpd-replicaset`
* **Image:** `httpd:latest`
* **Container Name:** `httpd-container`
* **Replicas:** `4`
* **Labels:**

  * `app: httpd_app`
  * `type: front-end`

---

<br>
<br>

# Understanding the Role of a ReplicaSet

A ReplicaSet ensures that a specified number of identical Pods are running at all times. If a Pod crashes, is deleted, or a node fails, the ReplicaSet automatically creates a replacement Pod.

It continuously compares:

* Desired state → `spec.replicas`
* Current state → Actual running Pods matching its selector

If there is a mismatch, it acts immediately to restore the desired count.

---

<br>
<br>

# Step 1: Create the YAML Manifest

ReplicaSets are created declaratively using a YAML manifest.

```bash
vi replicaset.yaml
```

### Manifest Content

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: httpd-replicaset
  labels:
    app: httpd_app
    type: front-end
spec:
  replicas: 4
  selector:
    matchLabels:
      app: httpd_app
      type: front-end
  template:
    metadata:
      labels:
        app: httpd_app
        type: front-end
    spec:
      containers:
      - name: httpd-container
        image: httpd:latest
```

### Important Configuration Points

* `spec.replicas` defines how many Pods must always run.
* `spec.selector.matchLabels` determines which Pods belong to this ReplicaSet.
* `spec.template.metadata.labels` defines labels assigned to created Pods.
* The selector labels must exactly match the template labels.

If they do not match, the ReplicaSet will not recognize its own Pods.

---

<br>
<br>

# Step 2: Apply the Configuration

Deploy the ReplicaSet into the cluster:

```bash
kubectl apply -f replicaset.yaml
```

Expected output:

```text
replicaset.apps/httpd-replicaset created
```

This instructs the Kubernetes API server to store the configuration and create 4 Pods immediately.

---

<br>
<br>

# Step 3: Verification

## Check ReplicaSet Status

```bash
kubectl get rs

# OUTPUT:

NAME               DESIRED   CURRENT   READY   AGE
httpd-replicaset   4         4         2       8s
```

Expected columns:

* DESIRED → 4
* CURRENT → 4
* READY → 4

All values should match.

## Check Pods

```bash
kubectl get pods

# OUTPUT

thor@jumphost ~$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
httpd-replicaset-5cbnv   1/1     Running   0          16s
httpd-replicaset-8cwfh   1/1     Running   0          16s
httpd-replicaset-ggcpf   1/1     Running   0          16s
httpd-replicaset-zzss9   1/1     Running   0          16s
```

You should see 4 Pods with names similar to:

```text
httpd-replicaset-xxxxx
```

## Describe ReplicaSet

```bash
kubectl describe rs httpd-replicaset

# OUTPUT

thor@jumphost ~$ kubectl describe rs httpd-replicaset
Name:         httpd-replicaset
Namespace:    default
Selector:     app=httpd_app,type=front-end
Labels:       app=httpd_app
              type=front-end
Annotations:  <none>
Replicas:     4 current / 4 desired
Pods Status:  4 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=httpd_app
           type=front-end
  Containers:
   httpd-container:
    Image:         httpd:latest
    Port:          <none>
    Host Port:     <none>
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: httpd-replicaset-5cbnv
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: httpd-replicaset-ggcpf
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: httpd-replicaset-zzss9
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: httpd-replicaset-8cwfh
```

Verify:

* Selector matches labels
* Container name is `httpd-container`
* Image is `httpd:latest`

---

<br>
<br>

# How ReplicaSet Works Internally

1. The ReplicaSet controller watches the cluster state.
2. It counts Pods matching its selector.
3. If running Pods < desired replicas → It creates new Pods.
4. If running Pods > desired replicas → It terminates extra Pods.

The controller performs continuous reconciliation to maintain stability.

---

<br>
<br>

# Selector and Label Relationship

There are two critical sections:

* `spec.template.metadata.labels` → Labels applied to created Pods
* `spec.selector.matchLabels` → Rule used to identify Pods owned by this ReplicaSet

These must match exactly. Kubernetes uses this match to determine ownership.

---

<br>
<br>

# ReplicaSet vs Deployment

Although ReplicaSets can be created directly, modern Kubernetes practice prefers using Deployments.

* ReplicaSet → Maintains Pod count only
* Deployment → Manages ReplicaSets and enables rolling updates, rollbacks, and controlled rollout strategies

When using a Deployment, Kubernetes automatically creates and manages ReplicaSets internally.

---

<br>
<br>

# Key Outcome

The ReplicaSet `httpd-replicaset` is successfully deployed with 4 running `httpd` Pods. The cluster now guarantees high availability by automatically maintaining the defined replica count.
