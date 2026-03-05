# Kubernetes Level 02 Day 04: Print Environment Variables

This document outlines the solution for Kubernetes Level 02 Day 04. The objective was to create a Pod that utilizes environment variables to output a concatenated greeting message to the console.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Create the YAML Manifest](#1-create-the-yaml-manifest)
    * [2. Apply the Configuration](#2-apply-the-configuration)
    * [3. Verification](#3-verification)
3.  [Deep Dive: Environment Variables in Kubernetes](#deep-dive-environment-variables-in-kubernetes)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Provision a Pod that prints a greeting message constructed from multiple injected environment variables.

* **Pod Name:** `print-envars-greeting`
* **Container Name:** `print-env-container`
* **Image:** `bash`
* **Environment Variables:**
    * `GREETING="Welcome to"`
    * `COMPANY="Stratos"`
    * `GROUP="Industries"`
* **Command:** `["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']`
* **Restart Policy:** `Never`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the YAML Manifest
<a name="1-create-the-yaml-manifest"></a>
We need to create a declarative YAML file to properly define the Pod, its container, the specific command, and the necessary environment variables.

**Command:**
```bash
vi pod.yaml
```

**Content:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-envars-greeting
spec:
  containers:
  - name: print-env-container
    image: bash
    command: ["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']
    env:
    - name: GREETING
      value: "Welcome to"
    - name: COMPANY
      value: "Stratos"
    - name: GROUP
      value: "Industries"
  restartPolicy: Never
```

### 2. Apply the Configuration
<a name="2-apply-the-configuration"></a>
Use `kubectl` to create the Pod in the cluster.

**Command:**
```bash
kubectl apply -f pod.yaml
```
* **Expected Output:** `pod/print-envars-greeting created`

### 3. Verification
<a name="3-verification"></a>
Since the Pod runs a simple `echo` command and the restart policy is set to `Never`, the container will start, print the message to standard output, and then immediately terminate (entering the `Completed` state).

**Check the Pod Status:**
```bash
kubectl get pods
```
* Wait until the status changes from `ContainerCreating` to `Completed`.

**Check the Logs:**
To verify the output, retrieve the logs from the Pod.
```bash
kubectl logs -f print-envars-greeting
```
* **Expected Output:** `Welcome to Stratos Industries`

---

## Deep Dive: Environment Variables in Kubernetes
<a name="deep-dive-environment-variables-in-kubernetes"></a>

### Why Use Environment Variables?
Environment variables allow you to externalize configuration data from your container images. This means you can use the exact same `bash` image in different environments (Development, Staging, Production) just by changing the injected environment variables in the Pod definition, adhering to the principles of the Twelve-Factor App methodology.

### `$(VAR)` Syntax in Kubernetes
In the `command` block, the task requested the exact syntax: `'echo "$(GREETING) $(COMPANY) $(GROUP)"'`. 
When using the `$(VAR)` syntax inside a Kubernetes command array, Kubernetes can evaluate and expand these variables dynamically before the container starts, provided the variables are defined in the `env` block.

### `restartPolicy: Never`
By default, Pods have a `restartPolicy` of `Always`. Since this specific container runs a finite `echo` command and completes its task immediately, an `Always` policy would cause Kubernetes to endlessly restart the container in a "CrashLoopBackOff" state. Setting `restartPolicy: Never` tells Kubernetes that it is acceptable for this Pod to finish execution and terminate successfully.
  
