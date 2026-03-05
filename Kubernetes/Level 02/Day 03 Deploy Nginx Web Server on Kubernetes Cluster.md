# Kubernetes Level 02 Day 03: Deploy Nginx Web Server on Kubernetes Cluster

This document outlines the solution for Kubernetes Level 02 Day 03. The objective was to deploy a highly available static website using an Nginx Deployment with multiple replicas and to expose it externally using a NodePort Service.

## Table of Contents
- [Kubernetes Level 02 Day 03: Deploy Nginx Web Server on Kubernetes Cluster](#kubernetes-level-02-day-03-deploy-nginx-web-server-on-kubernetes-cluster)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Unified Manifest File](#1-create-the-unified-manifest-file)
    - [2. Apply the Configuration](#2-apply-the-configuration)
    - [3. Verification](#3-verification)
  - [Deep Dive: Kubernetes Networking](#deep-dive-kubernetes-networking)
    - [Deployments and Selectors](#deployments-and-selectors)
    - [The NodePort Service Type](#the-nodeport-service-type)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a scalable Nginx web server deployment and expose it to the network.

* **Deployment Configuration:**
    * Name: `nginx-deployment`
    * Replicas: `3`
    * Image: `nginx:latest`
    * Container Name: `nginx-container`
* **Service Configuration:**
    * Name: `nginx-service`
    * Type: `NodePort`
    * NodePort: `30011`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Unified Manifest File
<a name="1-create-the-unified-manifest-file"></a>
We can define both the Deployment and the Service in a single declarative YAML file by separating them with three dashes (`---`).

**Command:**
```bash
vi nginx-setup.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-app
  template:
    metadata:
      labels:
        app: nginx-app
    spec:
      containers:
      - name: nginx-container
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx-app  # This MUST match the labels in the Deployment template
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30011
```

### 2. Apply the Configuration
<a name="2-apply-the-configuration"></a>
Use `kubectl` to create the resources defined in the YAML file on the cluster.

**Command:**
```bash
kubectl apply -f nginx-setup.yaml
```
* **Expected Output:**
  ```text
  deployment.apps/nginx-deployment created
  service/nginx-service created
  ```

### 3. Verification
<a name="3-verification"></a>
Ensure that the Deployment has successfully spun up 3 replicas and the Service is correctly exposing the NodePort.

**Check the Deployment and Pods:**
```bash
kubectl get deployments
kubectl get pods
```
* You should see `nginx-deployment` with `3/3` ready replicas.
* You should see three individual pods running (e.g., `nginx-deployment-xxxxx-xxxxx`).

**Check the Service:**
```bash
kubectl get svc nginx-service
```
* **Expected Output:** The `PORT(S)` column should show `80:30011/TCP`.

**Test Application Accessibility:**
You can test if the Nginx server is responding via the NodePort on the local cluster node.
```bash
curl http://localhost:30011
```
* You should see the default HTML response `<!DOCTYPE html>... Welcome to nginx! ...`.

---

## Deep Dive: Kubernetes Networking
<a name="deep-dive-kubernetes-networking"></a>

### Deployments and Selectors
In the YAML file, the Deployment creates Pods stamped with the label `app: nginx-app`. 
The Service uses a `selector` block looking for that exact same label (`app: nginx-app`). This is how Kubernetes knows which Pods the Service should route traffic to. Even if Pods are destroyed and recreated with new IP addresses, the Service dynamically tracks them via this label.

### The NodePort Service Type
A `NodePort` service is the most basic way to get external traffic directly to your service.
* **`targetPort: 80`**: The port that the container is actually listening on internally (Nginx's default port).
* **`port: 80`**: The port the Service listens on internally within the cluster.
* **`nodePort: 30011`**: Kubernetes opens this port on *every single node* (VM/Server) in the cluster. Any traffic arriving at `<NodeIP>:30011` is forwarded to the Service, which then load-balances it to one of the 3 Pods (`targetPort 80`).
  
