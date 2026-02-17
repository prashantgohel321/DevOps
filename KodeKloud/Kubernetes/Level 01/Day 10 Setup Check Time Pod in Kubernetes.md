# Kubernetes Level 01 – Day 10: Set Up Time Check Pod

This document explains how to configure a Pod that reads configuration dynamically from a ConfigMap, runs a continuous loop command using that configuration, and writes output to a mounted volume.

The goal is to combine namespace isolation, environment configuration, volumes, and shell execution in a single working example.

---

<br>
<br>

- [Kubernetes Level 01 – Day 10: Set Up Time Check Pod](#kubernetes-level-01--day-10-set-up-time-check-pod)
  - [Objective](#objective)
- [Understanding the Architecture](#understanding-the-architecture)
- [Step 1: Create Namespace](#step-1-create-namespace)
- [Step 2: Create ConfigMap](#step-2-create-configmap)
- [Step 3: Create Pod Manifest](#step-3-create-pod-manifest)
  - [Manifest Content](#manifest-content)
- [Explanation of Critical Sections](#explanation-of-critical-sections)
  - [Environment Variable from ConfigMap](#environment-variable-from-configmap)
  - [Volume Definition](#volume-definition)
  - [Volume Mount](#volume-mount)
  - [Shell Command Execution](#shell-command-execution)
- [Step 4: Apply and Verify](#step-4-apply-and-verify)
  - [Deploy the Pod](#deploy-the-pod)
  - [Check Pod Status](#check-pod-status)
  - [Verify Log Output](#verify-log-output)
- [Internal Flow of Execution](#internal-flow-of-execution)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Deploy a logging Pod with the following configuration:

* **Namespace:** `datacenter`
* **Pod Name:** `time-check`
* **Image:** `busybox:latest`
* **ConfigMap:** `time-config` → `TIME_FREQ=5`
* **Environment Variable:** `TIME_FREQ`
* **Volume Name:** `log-volume`
* **Mount Path:** `/opt/dba/time`
* **Action:** Continuously write date output to `/opt/dba/time/time-check.log` every TIME_FREQ seconds

---

<br>
<br>

# Understanding the Architecture

This setup connects four important Kubernetes components:

1. Namespace → Logical isolation
2. ConfigMap → External configuration
3. Volume → File persistence inside Pod lifecycle
4. Container command → Loop execution using shell

The Pod reads the frequency value from a ConfigMap and uses it to control how often logs are written.

---

<br>
<br>

# Step 1: Create Namespace

Ensure the namespace exists before creating resources inside it.

```bash
kubectl create namespace datacenter
```

Namespaces isolate resources logically within the cluster.

---

<br>
<br>

# Step 2: Create ConfigMap

Create a ConfigMap to store the execution interval.

```bash
kubectl create configmap time-config \
  --from-literal=TIME_FREQ=5 \
  -n datacenter
```

This creates a key-value pair:

TIME_FREQ=5

The Pod will later consume this value as an environment variable.

---

<br>
<br>

# Step 3: Create Pod Manifest

Create the YAML file:

```bash
vi pod.yaml
```

## Manifest Content

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: time-check
  namespace: datacenter
spec:
  containers:
  - name: time-check
    image: busybox:latest
    env:
    - name: TIME_FREQ
      valueFrom:
        configMapKeyRef:
          name: time-config
          key: TIME_FREQ
    volumeMounts:
    - name: log-volume
      mountPath: /opt/dba/time
    command: ["/bin/sh", "-c"]
    args:
    - while true; do date >> /opt/dba/time/time-check.log; sleep $TIME_FREQ; done
  volumes:
  - name: log-volume
    emptyDir: {}
```

---

<br>
<br>

# Explanation of Critical Sections

## Environment Variable from ConfigMap

```yaml
valueFrom:
  configMapKeyRef:
    name: time-config
    key: TIME_FREQ
```

This pulls the TIME_FREQ value directly from the ConfigMap and injects it into the container environment.

The container does not hardcode the value. It reads it dynamically.

---

<br>
<br>

## Volume Definition

```yaml
volumes:
- name: log-volume
  emptyDir: {}
```

`emptyDir` creates a temporary storage space available as long as the Pod exists.

It survives container restarts but is deleted when the Pod is deleted.

---

<br>
<br>

## Volume Mount

```yaml
volumeMounts:
- name: log-volume
  mountPath: /opt/dba/time
```

This makes the `emptyDir` storage accessible inside the container at the given path.

---

<br>
<br>

## Shell Command Execution

```yaml
command: ["/bin/sh", "-c"]
args:
- while true; do date >> /opt/dba/time/time-check.log; sleep $TIME_FREQ; done
```

Why `/bin/sh -c` is necessary:

* The `>>` operator requires shell processing
* `$TIME_FREQ` requires environment variable expansion

Without invoking the shell, variable expansion and redirection would not work properly.

The loop does:

1. Write current date to file
2. Sleep for TIME_FREQ seconds
3. Repeat indefinitely

---

<br>
<br>

# Step 4: Apply and Verify

## Deploy the Pod

```bash
kubectl apply -f pod.yaml
```

## Check Pod Status

```bash
kubectl get pods -n datacenter
```

Status should be `Running`.

## Verify Log Output

```bash
kubectl exec -it time-check -n datacenter -- cat /opt/dba/time/time-check.log
```

You should see timestamps printed at 5-second intervals.

---

<br>
<br>

# Internal Flow of Execution

1. Namespace is created
2. ConfigMap stores configuration
3. Pod starts and reads environment variable
4. Volume is mounted
5. Shell loop executes continuously
6. Timestamps are appended to file

If the container restarts, the file remains intact because `emptyDir` belongs to the Pod lifecycle, not the container.

---

<br>
<br>

# Key Outcome

The `time-check` Pod runs inside the `datacenter` namespace. It dynamically reads configuration from a ConfigMap and writes time logs into a mounted volume at controlled intervals. This demonstrates configuration decoupling, storage usage, and runtime scripting inside Kubernetes.
