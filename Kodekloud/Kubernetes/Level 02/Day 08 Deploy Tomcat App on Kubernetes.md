# Kubernetes Level 02 Day 08: Deploy Tomcat App on Kubernetes

This document outlines the solution for Kubernetes Level 02 Day 08. The objective was to deploy a Java-based Tomcat application within a dedicated namespace and expose it via a NodePort service.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create the Namespace](#1-create-the-namespace)
    * [2. Define the Manifests](#2-define-the-manifests)
    * [3. Apply the Configuration](#3-apply-the-configuration)
    * [4. Verification](#4-verification)
3.  [Deep Dive: Tomcat on Kubernetes](#deep-dive-tomcat-on-kubernetes)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a Tomcat application stack in the `tomcat-namespace-xfusion` namespace.

* **Namespace:** `tomcat-namespace-xfusion`
* **Deployment:**
    * Name: `tomcat-deployment-xfusion`
    * Replicas: `1`
    * Container Name: `tomcat-container-xfusion`
    * Image: `gcr.io/kodekloud/centos-ssh-enabled:tomcat`
    * Container Port: `8080`
* **Service:**
    * Name: `tomcat-service-xfusion`
    * Type: `NodePort`
    * NodePort: `32227`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Namespace
<a name="1-create-the-namespace"></a>
Start by isolating the Tomcat application resources.

**Command:**
```bash
kubectl create namespace tomcat-namespace-xfusion
```

### 2. Define the Manifests
<a name="2-define-the-manifests"></a>
Create a single YAML file containing both the Deployment and the Service configurations. Using a shared label like `app: tomcat-app` will link the service to the deployment.

**Command:**
```bash
vi tomcat-setup.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-deployment-xfusion
  namespace: tomcat-namespace-xfusion
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat-app
  template:
    metadata:
      labels:
        app: tomcat-app
    spec:
      containers:
      - name: tomcat-container-xfusion
        image: gcr.io/kodekloud/centos-ssh-enabled:tomcat
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: tomcat-service-xfusion
  namespace: tomcat-namespace-xfusion
spec:
  type: NodePort
  selector:
    app: tomcat-app
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 32227
```

### 3. Apply the Configuration
<a name="3-apply-the-configuration"></a>
Apply the declarative configuration to the cluster.

**Command:**
```bash
kubectl apply -f tomcat-setup.yaml
```
* **Output:**
    ```text
    deployment.apps/tomcat-deployment-xfusion created
    service/tomcat-service-xfusion created
    ```

### 4. Verification
<a name="4-verification"></a>
Ensure the pod is running and the service is correctly routing traffic.

**Check Pod Status:**
```bash
kubectl get pods -n tomcat-namespace-xfusion
```
*Wait until the pod shows `1/1` under the READY column and status is `Running`.*

**Check Service Details:**
```bash
kubectl get svc -n tomcat-namespace-xfusion
```
*Verify that `tomcat-service-xfusion` maps port `8080:32227/TCP`.*

**Access the UI:**
Once the pod is ready, open the provided browser or web view. Access the application via the Node's IP address on port `32227` (e.g., `http://<node-ip>:32227`). You should see the default Tomcat manager or welcome page.

---

## Deep Dive: Tomcat on Kubernetes
<a name="deep-dive-tomcat-on-kubernetes"></a>

### The Container Image
The image used (`gcr.io/kodekloud/centos-ssh-enabled:tomcat`) is a specialized CentOS-based image with Tomcat pre-installed and SSH enabled. In a standard production environment, you would typically use an official slim image like `tomcat:9-jre11-openjdk-slim` to reduce the attack surface and image size.

### Label Matchmaking
The `selector` block in the Service is the "glue" of Kubernetes networking.
* **Service Selector:** `app: tomcat-app`
* **Deployment Pod Template Label:** `app: tomcat-app`
If these do not match exactly, the Service will have no endpoints and will fail to route traffic to your application, resulting in "Connection Refused" or "Timeout" errors.

### NodePort Selection
By default, Kubernetes NodePorts are assigned from the `30000-32767` range. This task specified a precise port (`32227`), which is a common requirement when integrating with external firewalls or legacy load balancers that expect traffic on specific ports.
   
