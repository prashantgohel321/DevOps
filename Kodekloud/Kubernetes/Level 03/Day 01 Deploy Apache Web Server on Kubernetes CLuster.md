# Kubernetes Level 03 Day 01: Deploy Apache Web Server

This document outlines the solution for Kubernetes Level 03 Day 01. The objective was to provision a highly available Apache web server (`httpd`) within a dedicated namespace and expose it via a specific NodePort for external access.

## Table of Contents
- [Kubernetes Level 03 Day 01: Deploy Apache Web Server](#kubernetes-level-03-day-01-deploy-apache-web-server)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Namespace](#1-create-the-namespace)
    - [2. Define the Application Manifest](#2-define-the-application-manifest)
    - [3. Apply and Verify](#3-apply-and-verify)
  - [Deep Dive: Component Breakdown](#deep-dive-component-breakdown)
    - [The Namespace Constraint](#the-namespace-constraint)
    - [Replica Management](#replica-management)
    - [NodePort Mapping](#nodeport-mapping)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy an Apache stack in a custom namespace with specific port mapping.

* **Namespace:** `httpd-namespace-nautilus`
* **Deployment:**
    * Name: `httpd-deployment-nautilus`
    * Replicas: `2`
    * Image: `httpd:latest`
* **Service:**
    * Name: `httpd-service-nautilus`
    * Type: `NodePort`
    * NodePort: `30004`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Namespace
<a name="1-create-the-namespace"></a>
The first step is to create the logical isolation layer for the Apache deployment.

**Command:**
```bash
kubectl create namespace httpd-namespace-nautilus
```

### 2. Define the Application Manifest
<a name="2-define-the-application-manifest"></a>
We will create a single YAML file containing both the Deployment and the Service. This ensures that the Pod labels and Service selector are perfectly aligned within the same namespace.

**Command:**
```bash
vi apache-deploy.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-deployment-nautilus
  namespace: httpd-namespace-nautilus
  labels:
    app: apache-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apache-app
  template:
    metadata:
      labels:
        app: apache-app
    spec:
      containers:
      - name: httpd-container
        image: httpd:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpd-service-nautilus
  namespace: httpd-namespace-nautilus
spec:
  type: NodePort
  selector:
    app: apache-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30004
```

### 3. Apply and Verify
<a name="3-apply-and-verify"></a>
Apply the manifest to the cluster.

**Command:**
```bash
kubectl apply -f apache-deploy.yaml
```

**Verify the Deployment:**
```bash
kubectl get all -n httpd-namespace-nautilus
```
* **Expected Output:**
    * 2 Pods in `Running` state.
    * 1 Deployment showing `2/2` available.
    * 1 Service showing type `NodePort` with mapping `80:30004/TCP`.

**Test Accessibility:**
You can test the deployment by curling the NodePort from the control plane:
```bash
curl http://localhost:30004
# Result: <html><body><h1>It works!</h1></body></html>
```

---

## Deep Dive: Component Breakdown
<a name="deep-dive-component-breakdown"></a>

### The Namespace Constraint
By specifying `namespace: httpd-namespace-nautilus` in the `metadata` of both resources, we ensure they are grouped together. If you run `kubectl get pods` without the `-n` flag, you will not see these pods, as they are isolated from the `default` namespace.

### Replica Management
Setting `replicas: 2` ensures high availability. If one Apache pod crashes or the node it is running on fails, the Deployment controller will automatically spin up a new instance to maintain the desired count of 2.

### NodePort Mapping
The Service acts as the entry point.
* **`port: 80`**: The internal port other services in the cluster use to talk to Apache.
* **`targetPort: 80`**: The port inside the container where Apache is listening.
* **`nodePort: 30004`**: The static port opened on every node's IP address to allow traffic from outside the Kubernetes cluster.
   
