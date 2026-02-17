# Kubernetes Level 01 – Day 11: Resolve Pod Deployment Issue

This document explains how to troubleshoot and fix a Pod that is failing due to an incorrect container image tag. The issue prevented the `webserver` Pod from reaching the Running state.

---

<br>
<br>

- [Kubernetes Level 01 – Day 11: Resolve Pod Deployment Issue](#kubernetes-level-01--day-11-resolve-pod-deployment-issue)
  - [Objective](#objective)
- [Understanding the Problem](#understanding-the-problem)
- [Step 1: Identify the Exact Error](#step-1-identify-the-exact-error)
- [Step 2: Export Current Pod Definition](#step-2-export-current-pod-definition)
- [Step 3: Fix the Image Tag](#step-3-fix-the-image-tag)
- [Step 4: Replace the Pod](#step-4-replace-the-pod)
- [Step 5: Verify](#step-5-verify)
- [Deep Dive: What is ImagePullBackOff?](#deep-dive-what-is-imagepullbackoff)
- [Common Causes of ImagePullBackOff](#common-causes-of-imagepullbackoff)
- [Internal Flow During Image Pull](#internal-flow-during-image-pull)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Fix the Pod named `webserver` so that both containers run successfully.

* **Pod Name:** `webserver`
* **Container 1:** `nginx-container` (failing)
* **Container 2:** `sidecar-container` (`ubuntu:latest`) (running)
* **Target State:** `2/2 Running`

---

<br>
<br>

# Understanding the Problem

The Pod is partially running. One container starts correctly, but the other fails during image pull.

When you check Pod status:

```bash
kubectl get pod webserver
```

You may see:

```text
ImagePullBackOff
```

This indicates that Kubernetes cannot download the container image from the registry.

---

<br>
<br>

# Step 1: Identify the Exact Error

Describe the Pod to inspect events:

```bash
kubectl describe pod webserver
```

In the Events section, you may see something similar to:

```text
Failed to pull image "nginx:latests": not found
```

This shows the image tag is incorrect.

The correct tag is `nginx:latest`, not `nginx:latests`.

---

<br>
<br>

# Step 2: Export Current Pod Definition

Extract the YAML configuration:

```bash
kubectl get pod webserver -o yaml > webserver.yaml
```

---

<br>
<br>

# Step 3: Fix the Image Tag

Open the file:

```bash
vi webserver.yaml
```

Locate the container definition for `nginx-container`.

Incorrect configuration:

```yaml
- image: nginx:latests
  imagePullPolicy: IfNotPresent
  name: nginx-container
```

Correct it to:

```yaml
- image: nginx:latest
  imagePullPolicy: IfNotPresent
  name: nginx-container
```

Remove unnecessary runtime-generated fields if needed (such as `resourceVersion`, `uid`, and `status`) before reapplying.

---

<br>
<br>

# Step 4: Replace the Pod

Since Pods are immutable regarding container image fields, recreate it.

Option 1:

```bash
kubectl replace --force -f webserver.yaml
```

Option 2:

```bash
kubectl delete pod webserver
kubectl apply -f webserver.yaml
```

This deletes the broken Pod and creates a corrected version.

---

<br>
<br>

# Step 5: Verify

Check status:

```bash
kubectl get pod webserver
```

Expected output:

```text
webserver   2/2   Running   0   5s
```

Both containers should now be operational.

---

<br>
<br>

# Deep Dive: What is ImagePullBackOff?

When Kubernetes attempts to pull a container image and fails, it retries with increasing delay intervals. This retry mechanism is called exponential backoff.

`ImagePullBackOff` means:

* Image pull failed
* Kubernetes is waiting before retrying

It does not mean the Pod will never recover; it retries automatically.

---

<br>
<br>

# Common Causes of ImagePullBackOff

1. Typographical error in image name or tag
2. Image does not exist in registry
3. Authentication failure for private registry
4. Network connectivity problems

In this case, the issue was a simple typo in the tag (`latests`).

---

<br>
<br>

# Internal Flow During Image Pull

1. Kubelet receives Pod spec
2. It checks if image exists locally
3. If not, it contacts container registry
4. If image not found → Pull fails
5. Kubelet enters backoff retry mode

Correcting the image tag resolves the issue immediately.

---

<br>
<br>

# Key Outcome

The `webserver` Pod has been corrected and is now running both containers successfully. The issue was identified through event inspection and resolved by fixing an invalid image tag and recreating the Pod.
