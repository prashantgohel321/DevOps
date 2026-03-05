# Kubernetes Level 02 Day 10: Troubleshoot Deployment Issues

This document outlines the troubleshooting and resolution process for Kubernetes Level 02 Day 10. An existing Redis deployment was broken after manual changes. By analyzing `describe` logs, two primary configuration errors were identified and corrected.

## Table of Contents
- [Kubernetes Level 02 Day 10: Troubleshoot Deployment Issues](#kubernetes-level-02-day-10-troubleshoot-deployment-issues)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Troubleshooting Process](#troubleshooting-process)
    - [1. Identify the Resource Issues](#1-identify-the-resource-issues)
    - [2. Analyze Pod Failure](#2-analyze-pod-failure)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Fix ConfigMap Typo](#1-fix-configmap-typo)
    - [2. Fix Image Tag Typo](#2-fix-image-tag-typo)
    - [3. Verification](#3-verification)
  - [Deep Dive: Common Deployment Errors](#deep-dive-common-deployment-errors)
    - [Missing ConfigMaps/Secrets](#missing-configmapssecrets)
    - [Image Tag Errors](#image-tag-errors)
    - [Idempotency and `kubectl edit`](#idempotency-and-kubectl-edit)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Resolve the failure of the `redis-deployment` to ensure the Redis app returns to a `Running` state.

* **Deployment Name:** `redis-deployment`
* **Current State:** 0/1 Available, Pod stuck in `ContainerCreating`.
* **Root Causes Found:**
    1.  Incorrect ConfigMap name reference (`redis-cofig` vs `redis-config`).
    2.  Incorrect container image tag (`redis:alpin` vs `redis:alpine`).

---

## Troubleshooting Process
<a name="troubleshooting-process"></a>

### 1. Identify the Resource Issues
<a name="1-identify-the-resource-issues"></a>
We start by checking the status of the deployment.
```bash
kubectl get deployments
```
* **Observation:** `AVAILABLE` is 0. 

Next, we describe the deployment to see the container specifications.
```bash
kubectl describe deployment redis-deployment
```
* **Findings:**
    * The Image is listed as `redis:alpin`.
    * The Volume named `config` is looking for a ConfigMap named `redis-cofig`.

### 2. Analyze Pod Failure
<a name="2-analyze-pod-failure"></a>
We look at the pod events to see why it won't start.
```bash
kubectl describe pod <redis-pod-name>
```
* **Critical Error Message:**
  `Warning  FailedMount  ... MountVolume.SetUp failed for volume "config" : configmap "redis-cofig" not found`

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

To resolve these issues, we need to edit the deployment configuration.

**Command:**
```bash
kubectl edit deployment redis-deployment
```

### 1. Fix ConfigMap Typo
<a name="1-fix-configmap-typo"></a>
In the editor, scroll down to the `volumes:` section at the bottom.

**Change:**
```yaml
      volumes:
      - name: config
        configMap:
          name: redis-cofig  # Change this
```
**To:**
```yaml
      volumes:
      - name: config
        configMap:
          name: redis-config # Fixed typo
```

### 2. Fix Image Tag Typo
<a name="2-fix-image-tag-typo"></a>
In the same editor, locate the `containers:` section.

**Change:**
```yaml
    spec:
      containers:
      - name: redis-container
        image: redis:alpin  # Change this
```
**To:**
```yaml
    spec:
      containers:
      - name: redis-container
        image: redis:alpine # Fixed typo
```

*Save and exit the editor (`:wq`).*

### 3. Verification
Verify that the deployment triggers a new rollout and the pod starts successfully.
```bash
kubectl rollout status deployment redis-deployment
kubectl get pods
```
* **Expected Output:** Pod status should be `Running` and Ready `1/1`.

---

## Deep Dive: Common Deployment Errors
<a name="deep-dive-common-deployment-errors"></a>

### Missing ConfigMaps/Secrets
If a Pod references a ConfigMap or Secret that does not exist, it will stay in the `ContainerCreating` or `Pending` state. Kubernetes will keep trying to find the resource, as seen in the "FailedMount" events.

### Image Tag Errors
Docker/Container images are case-sensitive and spelling-sensitive. 
* `redis:alpin` (Incorrect)
* `redis:alpine` (Correct)
If an image tag is wrong, the pod will usually enter `ImagePullBackOff`. However, because the ConfigMap was also missing in this task, the pod was stuck at the "Mounting Volumes" stage *before* it even attempted to pull the image.

### Idempotency and `kubectl edit`
`kubectl edit` allows for live debugging. When you save your changes, Kubernetes notices the difference between the "desired state" (your new YAML) and the "current state". It then terminates the old, broken pod and starts a new one with your fixes.
  
