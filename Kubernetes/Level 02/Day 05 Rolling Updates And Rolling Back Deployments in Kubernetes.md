# Kubernetes Level 02 Day 05: Rolling Updates and Rolling Back Deployments

This document outlines the solution for Kubernetes Level 02 Day 05. The objective was to practice managing the lifecycle of an application deployment by configuring a custom rolling update strategy, upgrading the application version, and finally rolling back the deployment to its previous stable state.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create Namespace](#1-create-namespace)
    * [2. Define Deployment and Service Manifest](#2-define-deployment-and-service-manifest)
    * [3. Apply the Initial Configuration](#3-apply-the-initial-configuration)
    * [4. Execute Rolling Update](#4-execute-rolling-update)
    * [5. Perform Rollback](#5-perform-rollback)
3.  [Deep Dive: Deployment Strategies](#deep-dive-deployment-strategies)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Test a production deployment process in a Dev environment by creating a custom deployment, upgrading it, and rolling it back.

* **Namespace:** `devops`
* **Deployment Name:** `httpd-deploy`
* **Replica Count:** `2`
* **Container Name:** `httpd`
* **Initial Image:** `httpd:2.4.25`
* **Strategy:** `RollingUpdate` (maxSurge=1, maxUnavailable=2)
* **Service:** `httpd-service` (Type: `NodePort`, nodePort: `30008`)
* **Target Update Image:** `httpd:2.4.43`
* **Final Action:** Rollback to the original version.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Namespace
<a name="1-create-namespace"></a>
Start by creating the requested namespace to isolate the resources.

**Command:**
```bash
kubectl create namespace devops
```

### 2. Define Deployment and Service Manifest
<a name="2-define-deployment-and-service-manifest"></a>
To precisely configure the rolling update strategy (`maxSurge` and `maxUnavailable`), we use a declarative YAML manifest for both the Deployment and the Service.

**Command:**
```bash
vi deployment.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deploy
  namespace: devops
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpd-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 2
  template:
    metadata:
      labels:
        app: httpd-app
    spec:
      containers:
      - name: httpd
        image: httpd:2.4.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-service
  namespace: devops
spec:
  type: NodePort
  selector:
    app: httpd-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30008
```

### 3. Apply the Initial Configuration
<a name="3-apply-the-initial-configuration"></a>
Deploy the initial version (`2.4.25`) to the cluster.

**Command:**
```bash
kubectl apply -f deployment.yaml
```

**Verify Initial State:**
```bash
kubectl get pods,svc -n devops
```
*Ensure the pods are running and the service is exposed on port 30008.*

### 4. Execute Rolling Update
<a name="4-execute-rolling-update"></a>
Upgrade the deployment to the newer image (`httpd:2.4.43`). Using `--record` saves the command in the revision history, which helps track changes.

**Command:**
```bash
kubectl set image deployment/httpd-deploy httpd=httpd:2.4.43 -n devops --record
```

**Verify the Update:**
Watch the rollout status to ensure all pods are updated successfully.
```bash
kubectl rollout status deployment/httpd-deploy -n devops
```
*Wait until it says "successfully rolled out".*

You can also verify the active image version:
```bash
kubectl describe deployment httpd-deploy -n devops | grep Image:
```
*(Should now show `httpd:2.4.43`)*

### 5. Perform Rollback
<a name="5-perform-rollback"></a>
Now, simulate a failure and revert the deployment to the previous stable state (`httpd:2.4.25`).

**Command:**
```bash
kubectl rollout undo deployment/httpd-deploy -n devops
```

**Final Verification:**
Ensure the deployment rolled back correctly.
```bash
kubectl rollout status deployment/httpd-deploy -n devops
kubectl describe deployment httpd-deploy -n devops | grep Image:
```
*(Should revert back to showing `httpd:2.4.25`)*

---

## Deep Dive: Deployment Strategies
<a name="deep-dive-deployment-strategies"></a>

### RollingUpdate Parameters
By default, Deployments use the `RollingUpdate` strategy to update pods in a rolling fashion, ensuring zero downtime. The speed and safety of this rollout are controlled by two parameters:

* **`maxSurge`**: (Defined as `1` in this task). This determines how many pods can be created *over* the desired replica count during the update. If replicas is 2, and maxSurge is 1, the deployment can scale up to a maximum of 3 pods simultaneously during the transition.
* **`maxUnavailable`**: (Defined as `2` in this task). This determines how many pods can be unavailable *below* the desired replica count during the update. If replicas is 2, and maxUnavailable is 2, both original pods could potentially be taken down simultaneously while the new ones spin up. *(Note: Setting maxUnavailable to a number equal to or higher than your replica count can cause temporary downtime if the new pods fail to start quickly, but it speeds up the rollout process).*

### Rollout History
Kubernetes maintains a history of ReplicaSets under the hood. When you run `kubectl rollout undo`, Kubernetes doesn't technically "downgrade" the image. Instead, it looks at the previous ReplicaSet definition and scales it back up, restoring the exact state of that revision.
  
