# Kubernetes Level 03 Day 03: Init Containers in Kubernetes

This document outlines the solution for Kubernetes Level 03 Day 03. The objective was to demonstrate the use of **Init Containers** to perform setup tasks that must complete before the main application container starts. Specifically, we initialize a shared volume with a message that the main container then reads.

## Table of Contents
- [Kubernetes Level 03 Day 03: Init Containers in Kubernetes](#kubernetes-level-03-day-03-init-containers-in-kubernetes)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the Deployment Manifest](#1-create-the-deployment-manifest)
    - [2. Apply the Configuration](#2-apply-the-configuration)
    - [3. Verification](#3-verification)
  - [Deep Dive: Kubernetes Init Containers](#deep-dive-kubernetes-init-containers)
    - [What are Init Containers?](#what-are-init-containers)
    - [Key Characteristics:](#key-characteristics)
    - [Why use `emptyDir`?](#why-use-emptydir)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy a pod where an Init Container prepares data for the main application.

* **Deployment Name:** `ic-deploy-datacenter`
* **Replicas:** `1`
* **Labels:** `app: ic-datacenter`
* **Init Container:**
    * Name: `ic-msg-datacenter`
    * Image: `fedora:latest`
    * Command: `echo Init Done - Welcome to xFusionCorp Industries > /ic/blog`
* **Main Container:**
    * Name: `ic-main-datacenter`
    * Image: `fedora:latest`
    * Command: `while true; do cat /ic/blog; sleep 5; done`
* **Storage:** Shared `emptyDir` volume named `ic-volume-datacenter` mounted at `/ic`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the Deployment Manifest
<a name="1-create-the-deployment-manifest"></a>
We use a YAML file to define the complex relationship between the init container, the main container, and the shared volume.

**Command:**
```bash
vi init-pod.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ic-deploy-datacenter
  labels:
    app: ic-datacenter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ic-datacenter
  template:
    metadata:
      labels:
        app: ic-datacenter
    spec:
      volumes:
      - name: ic-volume-datacenter
        emptyDir: {}
      
      # Init Containers run to completion before the main container starts
      initContainers:
      - name: ic-msg-datacenter
        image: fedora:latest
        command: ['/bin/bash', '-c', 'echo Init Done - Welcome to xFusionCorp Industries > /ic/blog']
        volumeMounts:
        - name: ic-volume-datacenter
          mountPath: /ic
      
      # The main application container
      containers:
      - name: ic-main-datacenter
        image: fedora:latest
        command: ['/bin/bash', '-c', 'while true; do cat /ic/blog; sleep 5; done']
        volumeMounts:
        - name: ic-volume-datacenter
          mountPath: /ic
```

### 2. Apply the Configuration
<a name="2-apply-the-configuration"></a>
Apply the manifest to your Kubernetes cluster.

**Command:**
```bash
kubectl apply -f init-pod.yaml
```

### 3. Verification
<a name="3-verification"></a>
Observe the Pod lifecycle as it transitions from the initialization phase to the running phase.

**Check Pod Status:**
```bash
kubectl get pods
```
* **Phase 1:** You will see `STATUS: Init:0/1`. This means the init container is running.
* **Phase 2:** You will see `STATUS: PodInitializing`.
* **Phase 3:** You will see `STATUS: Running`.

**Verify the Logs:**
The main container's command is to `cat` the file created by the init container. If the logs show the greeting, the task is successful.
```bash
kubectl logs -f deployment/ic-deploy-datacenter
```
* **Expected Output:**
  ```text
  Init Done - Welcome to xFusionCorp Industries
  Init Done - Welcome to xFusionCorp Industries
  ...
  ```

---

## Deep Dive: Kubernetes Init Containers
<a name="deep-dive-init-containers"></a>

### What are Init Containers?
Init Containers are specialized containers that run before app containers in a Pod. They can contain utilities or setup scripts not present in an app image.

### Key Characteristics:
1.  **Sequential Execution:** If a Pod has multiple init containers, they run one at a time in the order they are defined in the YAML.
2.  **Required Success:** Each init container must exit successfully (exit code 0) before the next one starts. If one fails, Kubernetes restarts the Pod until the init container succeeds (unless the `restartPolicy` is `Never`).
3.  **Isolation:** They offer a secure way to perform setup tasks. For example, an init container can have permissions to talk to a database to run migrations, while the main app container has restricted permissions.

### Why use `emptyDir`?
Since Init Containers run and then terminate, any data they generate inside their own filesystem is lost when they exit. By mounting a shared `emptyDir` volume, the Init Container can write configuration files or processed data that the main container can access once it spins up.
  
