# Kubernetes Level 02 Day 09: Deploy Node App on Kubernetes

This document outlines the solution for Kubernetes Level 02 Day 09. The objective was to deploy a Node.js application using a Deployment with multiple replicas and expose it through a NodePort service on a specific port.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create the Unified Manifest File](#1-create-the-unified-manifest-file)
    * [2. Apply the Configuration](#2-apply-the-configuration)
    * [3. Verification](#3-verification)
3.  [Deep Dive: NodePort and TargetPort](#deep-dive-nodeport-and-targetport)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a Node.js application stack and ensure it is accessible via the NodeApp interface.

* **Deployment:**
    * Name: `node-app-deployment` (Choice)
    * Image: `gcr.io/kodekloud/centos-ssh-enabled:node`
    * Replicas: `2`
    * Container Name: `node-container` (Choice)
* **Service:**
    * Name: `node-app-service` (Choice)
    * Type: `NodePort`
    * TargetPort: `8080`
    * NodePort: `30012`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Unified Manifest File
<a name="1-create-the-unified-manifest-file"></a>
We will create a YAML file that defines both the Deployment and the Service. This ensures consistency between the pod labels and the service selector.

**Command:**
```bash
vi node-app.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app-deployment
  labels:
    app: node-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-app
  template:
    metadata:
      labels:
        app: node-app
    spec:
      containers:
      - name: node-container
        image: gcr.io/kodekloud/centos-ssh-enabled:node
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: node-app-service
spec:
  type: NodePort
  selector:
    app: node-app
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30012
```

### 2. Apply the Configuration
<a name="2-apply-the-configuration"></a>
Apply the manifest using `kubectl`.

**Command:**
```bash
kubectl apply -f node-app.yaml
```
* **Output:**
    ```text
    deployment.apps/node-app-deployment created
    service/node-app-service created
    ```

### 3. Verification
<a name="3-verification"></a>
Ensure that the pods are running and the service is correctly routing traffic.

**Check Pod Status:**
```bash
kubectl get pods
```
*Wait until both pods show `1/1` under READY and status is `Running`.*

**Check Service Details:**
```bash
kubectl get svc node-app-service
```
*Verify the mapping shows `80:30012/TCP`.*

**Access the UI:**
Once verified, click the **NodeApp** button on the top bar of the lab environment. You should see the response from the Node.js application.

---

## Deep Dive: NodePort and TargetPort
<a name="deep-dive-nodeport-and-targetport"></a>

### Port Configuration Explained
In this task, we managed three different port levels:
1.  **ContainerPort (8080):** The port the Node.js application is listening on inside the container.
2.  **TargetPort (8080):** The port on the pod that the Service sends traffic to. This must match the port used by the application in the container.
3.  **Port (80):** The internal cluster port for the service. Other pods in the cluster can access this app via `http://node-app-service:80`.
4.  **NodePort (30012):** The port opened on every node's IP address. This allows external access via `http://<NodeIP>:30012`.

### High Availability
By setting `replicas: 2`, Kubernetes ensures that two instances of the application are running across the cluster. If one pod fails or a node goes down, the Deployment controller will automatically spin up a new instance to maintain the desired state of 2 replicas.
   
