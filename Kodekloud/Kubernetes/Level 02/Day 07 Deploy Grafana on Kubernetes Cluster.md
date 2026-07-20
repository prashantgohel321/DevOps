# Kubernetes Level 02 Day 07: Deploy Grafana on Kubernetes Cluster

This document outlines the solution for Kubernetes Level 02 Day 07. The objective was to provision Grafana, a powerful open-source analytics and interactive visualization web application, on a Kubernetes cluster and expose its UI using a NodePort Service.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Define the Manifests](#1-define-the-manifests)
    * [2. Apply the Configuration](#2-apply-the-configuration)
    * [3. Verification and Access](#3-verification-and-access)
3.  [Deep Dive: Grafana Deployment](#deep-dive-grafana-deployment)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy Grafana and ensure its web interface is accessible.

* **Deployment:**
    * Name: `grafana-deployment-xfusion`
    * Image: Any Grafana image (e.g., `grafana/grafana:latest`)
* **Service:**
    * Type: `NodePort`
    * NodePort: `32000`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Define the Manifests
<a name="1-define-the-manifests"></a>
Create a single YAML file containing both the Deployment and the Service configurations. Grafana typically runs its web interface on port `3000` internally.

**Command:**
```bash
vi grafana-setup.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-deployment-xfusion
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana-container
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 32000
```

### 2. Apply the Configuration
<a name="2-apply-the-configuration"></a>
Apply the declarative configuration to the cluster.

**Command:**
```bash
kubectl apply -f grafana-setup.yaml
```
* **Output:**
    ```text
    deployment.apps/grafana-deployment-xfusion created
    service/grafana-service created
    ```

### 3. Verification and Access
<a name="3-verification-and-access"></a>
Wait for the Grafana pod to fully initialize and become ready.

**Check Pod Status:**
```bash
kubectl get pods -l app=grafana
```
*Wait until the pod shows `1/1` under the READY column.*

**Check Service Configuration:**
```bash
kubectl get svc grafana-service
```
*Verify that the service maps port `3000:32000/TCP`.*

**Access the UI:**
Once the pod is running, open the provided browser or web view feature in your lab environment. Access Grafana via the Node's IP address on port `32000` (e.g., `http://<node-ip>:32000`).
You should see the Grafana login screen. (Default credentials are usually `admin` / `admin`).

---

## Deep Dive: Grafana Deployment
<a name="deep-dive-grafana-deployment"></a>

### Port Mappings
Understanding the port routing is crucial for web applications in Kubernetes:
* **`containerPort: 3000`**: Grafana's default web server port inside the container.
* **`targetPort: 3000`**: Where the Service sends traffic to (matching the containerPort).
* **`port: 3000`**: The port the Service exposes internally within the cluster.
* **`nodePort: 32000`**: The external port opened on all physical nodes to allow access from outside the cluster.

### Stateful vs Stateless
In this basic deployment, Grafana is running statelessly. If the pod restarts, any dashboards or data sources created manually through the UI will be lost because we didn't attach a Persistent Volume (PV). For production setups, a Persistent Volume must be mounted to `/var/lib/grafana` to ensure analytics configurations are saved permanently.
  
