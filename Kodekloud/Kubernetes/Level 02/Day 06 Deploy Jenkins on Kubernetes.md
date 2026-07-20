# Kubernetes Level 02 Day 06: Deploy Jenkins on Kubernetes

This document outlines the solution for Kubernetes Level 02 Day 06. The objective was to deploy a Jenkins Continuous Integration (CI) server onto a Kubernetes cluster, ensuring it is properly isolated within its own namespace and exposed to users via a NodePort service.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create Namespace](#1-create-namespace)
    * [2. Define the Manifests](#2-define-the-manifests)
    * [3. Apply the Configuration](#3-apply-the-configuration)
    * [4. Verification and Access](#4-verification-and-access)
3.  [Deep Dive: Jenkins on Kubernetes](#deep-dive-jenkins-on-kubernetes)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a Jenkins CI server accessible via the browser.

* **Namespace:** `jenkins`
* **Service:**
    * Name: `jenkins-service`
    * Type: `NodePort`
    * NodePort: `30008`
* **Deployment:**
    * Name: `jenkins-deployment`
    * Replicas: `1`
    * Labels: `app: jenkins`
    * Container Name: `jenkins-container`
    * Image: `jenkins/jenkins`
    * Container Port: `8080`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create Namespace
<a name="1-create-namespace"></a>
Start by creating the isolated environment (namespace) where the Jenkins resources will reside.

**Command:**
```bash
kubectl create namespace jenkins
```

### 2. Define the Manifests
<a name="2-define-the-manifests"></a>
Create a single YAML file containing both the Deployment and the Service configurations separated by `---`.

**Command:**
```bash
vi jenkins-setup.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins-deployment
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins-container
        image: jenkins/jenkins
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: jenkins
spec:
  type: NodePort
  selector:
    app: jenkins
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30008
```

### 3. Apply the Configuration
<a name="3-apply-the-configuration"></a>
Apply the declarative configuration to the cluster.

**Command:**
```bash
kubectl apply -f jenkins-setup.yaml
```
* **Output:**
    ```text
    deployment.apps/jenkins-deployment created
    service/jenkins-service created
    ```

### 4. Verification and Access
<a name="4-verification-and-access"></a>
Wait for the Jenkins pod to fully initialize. Jenkins is a heavy Java application, so it may take a minute to reach the `Running` state and become responsive.

**Check Pod Status:**
```bash
kubectl get pods -n jenkins
```
*Wait until the pod shows `1/1` under the READY column.*

**Check Service Configuration:**
```bash
kubectl get svc -n jenkins
```
*Verify that `jenkins-service` maps port `8080:30008/TCP`.*

**Access the UI:**
Once the pod is running, open the provided browser or web view feature in your lab environment. Access Jenkins via the Node's IP address on port `30008` (e.g., `http://<node-ip>:30008`).

*(Optional: Retrieve Initial Admin Password)*
If you are logging in to configure Jenkins, you will need the initial admin password. You can retrieve this by checking the container logs.
```bash
kubectl logs deployment/jenkins-deployment -n jenkins
```
Look for a block of text in the logs that looks like:
```text
Please use the following password to proceed to installation:

8a4b6c3d9e2f4a1b8c7d6e5f4a3b2c1d

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
```

---

## Deep Dive: Jenkins on Kubernetes
<a name="deep-dive-jenkins-on-kubernetes"></a>

### Why run Jenkins in Kubernetes?
Running Jenkins on Kubernetes is incredibly powerful because it allows Jenkins to spin up dynamic "Build Agents" (worker pods) on-demand to run CI/CD pipelines. This ensures that build environments are clean, isolated, and scalable, rather than maintaining static, heavy VM workers.

### The Port Configuration
* **Container Port (8080):** Jenkins natively runs a web server on port 8080 inside the container.
* **Target Port (8080):** The service routes traffic to port 8080 on the pods.
* **Port (8080):** The service's internal cluster port.
* **NodePort (30008):** A high port opened on every single physical node in the Kubernetes cluster. Any traffic hitting a node's IP on port 30008 is forwarded to the Jenkins service.
   
