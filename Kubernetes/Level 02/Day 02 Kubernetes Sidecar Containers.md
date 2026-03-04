# Kubernetes Level 02 – Day 02: Kubernetes Sidecar Containers

This document explains how to implement the Sidecar container pattern in Kubernetes. The goal is to deploy a multi-container Pod where a primary application container (Nginx) shares its logs with a helper container through a shared volume.

---

## Objective

Deploy a Pod with the following configuration:

* **Pod Name:** `webserver`
* **Shared Volume:** `shared-logs` (Type: `emptyDir`)

Main container:

* **Name:** `nginx-container`
* **Image:** `nginx:latest`
* **Mount Path:** `/var/log/nginx`

Sidecar container:

* **Name:** `sidecar-container`
* **Image:** `ubuntu:latest`
* **Mount Path:** `/var/log/nginx`
* **Command:** Continuously read Nginx log files and print them

---

# Understanding the Architecture

In Kubernetes, multiple containers can run inside the same Pod and share resources such as:

* Network namespace
* Volumes
* IPC namespace

The Sidecar pattern places a helper container next to the main application container. The helper container performs supporting tasks such as log collection, monitoring, configuration synchronization, or proxying.

In this scenario:

* Nginx generates log files
* The sidecar container reads those logs and outputs them

Both containers access the same files through a shared volume.

---

# Step 1: Create the Pod Manifest

Create the configuration file.

```bash
vi pod.yaml
```

### Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver
spec:
  volumes:
  - name: shared-logs
    emptyDir: {}

  containers:

  - name: nginx-container
    image: nginx:latest
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx

  - name: sidecar-container
    image: ubuntu:latest
    command: ["sh", "-c", "while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"]
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
```

---

# Explanation of Configuration

### Shared Volume

```yaml
volumes:
- name: shared-logs
  emptyDir: {}
```

The `emptyDir` volume is created when the Pod starts and is shared by both containers.

When the Pod terminates, the volume is removed.

---

### Nginx Container

The main application container writes logs into `/var/log/nginx`. Because this directory is backed by the shared volume, the log files become accessible to other containers.

---

### Sidecar Container

The sidecar container continuously reads the log files:

```
/var/log/nginx/access.log
/var/log/nginx/error.log
```

The command runs in an infinite loop and prints logs every 30 seconds.

This simulates a simple log streaming mechanism.

---

# Step 2: Apply the Configuration

Create the Pod in the cluster.

```bash
kubectl apply -f pod.yaml
```

Check Pod status:

```bash
kubectl get pods
```

Expected output:

```
webserver   2/2   Running
```

Both containers should be operational.

---

# Step 3: Verify Sidecar Functionality

Inspect the sidecar container logs.

```bash
kubectl logs webserver -c sidecar-container
```

Initially, logs may be empty until the Nginx server receives requests.

Once traffic hits the server, Nginx writes entries into the access and error logs, which the sidecar container will read and output.

---

# How the Sidecar Pattern Works

The Sidecar pattern extends application functionality without modifying the primary container image.

The main container focuses only on the core application logic.

The sidecar container handles auxiliary responsibilities such as:

* Log shipping
* Monitoring
* Metrics collection
* Configuration updates

Both containers share a lifecycle because they exist in the same Pod.

---

# Why This Pattern is Useful

Using a sidecar container allows separation of responsibilities.

Advantages include:

* Independent updates for logging or monitoring tools
* Reusable helper containers across multiple applications
* Cleaner application images without additional agents

For example, production systems often use sidecars like:

* Fluentd
* Logstash
* Promtail
* Envoy

These containers process logs or network traffic while the main container handles application requests.

---

# Key Outcome

The Pod `webserver` now runs two containers that share a logging directory through an `emptyDir` volume. The Nginx container generates logs while the sidecar container continuously reads and outputs them, demonstrating the Kubernetes Sidecar pattern.
