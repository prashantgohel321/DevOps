# Kubernetes Level 02 – Day 01: Kubernetes Shared Volumes

This document explains how to create a multi-container Pod where multiple containers share access to the same temporary storage. The purpose is to demonstrate how containers inside a single Pod can exchange data through a shared volume.

---

- [Kubernetes Level 02 – Day 01: Kubernetes Shared Volumes](#kubernetes-level-02--day-01-kubernetes-shared-volumes)
  - [Objective](#objective)
- [Understanding the Architecture](#understanding-the-architecture)
- [Step 1: Create the Pod Manifest](#step-1-create-the-pod-manifest)
    - [Manifest](#manifest)
    - [Important Details](#important-details)
- [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
- [Step 3: Test Shared Storage](#step-3-test-shared-storage)
  - [Create File in Container 1](#create-file-in-container-1)
  - [Read File from Container 2](#read-file-from-container-2)
- [How emptyDir Works Internally](#how-emptydir-works-internally)
- [Common Use Cases](#common-use-cases)
    - [Sidecar Pattern](#sidecar-pattern)
    - [Log Processing](#log-processing)
    - [Temporary Processing](#temporary-processing)
- [Key Outcome](#key-outcome)

<br>
<br>

## Objective

Create a Pod that contains two containers using a shared `emptyDir` volume.

Configuration requirements:

* **Pod Name:** `volume-share-datacenter`
* **Volume Name:** `volume-share`
* **Volume Type:** `emptyDir`

Container specifications:

Container 1:

* **Name:** `volume-container-datacenter-1`
* **Image:** `fedora:latest`
* **Mount Path:** `/tmp/blog`

Container 2:

* **Name:** `volume-container-datacenter-2`
* **Image:** `fedora:latest`
* **Mount Path:** `/tmp/apps`

Both containers should remain running so that the shared storage can be tested.

---

<br>
<br>

# Understanding the Architecture

A Pod can contain multiple containers that share the same:

* Network namespace
* IPC namespace
* Volumes

When a volume is mounted into multiple containers, all containers see the same underlying storage even if it appears under different paths inside each container.

This pattern is commonly used in:

* Sidecar containers
* Log collectors
* Data processors

---

<br>
<br>

# Step 1: Create the Pod Manifest

Create a YAML file describing the Pod.

```bash
vi pod.yaml
```

### Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-datacenter
spec:
  containers:
  - name: volume-container-datacenter-1
    image: fedora:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: volume-share
      mountPath: /tmp/blog

  - name: volume-container-datacenter-2
    image: fedora:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: volume-share
      mountPath: /tmp/apps

  volumes:
  - name: volume-share
    emptyDir: {}
```

### Important Details

`emptyDir` creates a temporary directory on the node when the Pod starts.

Both containers mount the same volume but at different paths:

* `/tmp/blog`
* `/tmp/apps`

Even though the paths differ, the underlying storage is identical.

The command `sleep 3600` ensures the containers stay alive. Without a long-running process, the container would exit immediately.

---

<br>
<br>

# Step 2: Apply the Configuration

Create the Pod using the manifest.

```bash
kubectl apply -f pod.yaml
```

Verify the Pod status:

```bash
kubectl get pods
```

Expected output:

```
volume-share-datacenter   2/2   Running
```

Both containers should be running.

---

<br>
<br>

# Step 3: Test Shared Storage

To confirm that the volume is shared, create a file from one container and read it from the other.

## Create File in Container 1

```bash
kubectl exec -it volume-share-datacenter \
  -c volume-container-datacenter-1 \
  -- /bin/sh -c "echo 'Shared Volume Test' > /tmp/blog/blog.txt"
```

This writes a file inside the mounted directory.

---

## Read File from Container 2

```bash
kubectl exec -it volume-share-datacenter \
  -c volume-container-datacenter-2 \
  -- cat /tmp/apps/blog.txt
```

Expected output:

```
Shared Volume Test
```

This confirms that both containers are reading and writing to the same volume.

---

<br>
<br>

# How emptyDir Works Internally

`emptyDir` volumes behave as temporary storage attached to a Pod.

Lifecycle behavior:

1. Created when the Pod is scheduled to a node
2. Initially empty
3. Accessible by all containers in the Pod
4. Deleted automatically when the Pod is removed

The data survives container restarts but does not survive Pod deletion.

---

<br>
<br>

# Common Use Cases

Shared volumes inside Pods are frequently used in these patterns:

### Sidecar Pattern

A helper container performs a supporting task such as fetching configuration or logs, writing the output to a shared directory.

### Log Processing

Application container writes logs to a shared volume while another container processes or ships the logs to a monitoring system.

### Temporary Processing

Multiple containers cooperate to process intermediate data stored in shared storage.

---

<br>
<br>

# Key Outcome

The Pod `volume-share-datacenter` runs two containers that share an `emptyDir` volume. Data written by one container becomes immediately accessible to the other container, demonstrating how Kubernetes enables container collaboration within the same Pod.
