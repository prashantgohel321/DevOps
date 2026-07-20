# Kubernetes Level 03 Day 04: Persistent Volumes in Kubernetes

This document explains the solution for the Kubernetes Level 03 Day 04 task. The goal of this exercise is to understand how persistent storage works inside a Kubernetes cluster and how an application can store data outside the lifecycle of a container.

Containers are designed to be temporary. When a container stops or is recreated, any data stored inside it disappears. In real systems this is a problem because applications such as web servers, databases, or logging systems need a place where data can survive container restarts. Kubernetes solves this problem using **Persistent Volumes (PV)** and **Persistent Volume Claims (PVC)**.

In this task, a persistent volume is created on the node using a host directory, a claim is made for part of that storage, and a web server pod mounts that storage so the application can read or write data from it.

---

# Task Requirements

Resource configuration required for this task:

* **PersistentVolume Name:** `pv-devops`
* **Storage Class:** `manual`
* **Capacity:** `4Gi`
* **Access Mode:** `ReadWriteOnce`
* **Volume Type:** `hostPath`
* **Host Directory Path:** `/mnt/dba`

Persistent Volume Claim:

* **Claim Name:** `pvc-devops`
* **Storage Class:** `manual`
* **Requested Storage:** `1Gi`
* **Access Mode:** `ReadWriteOnce`

Pod Configuration:

* **Pod Name:** `pod-devops`
* **Container Name:** `container-devops`
* **Image:** `nginx:latest`
* **Volume Mount Location:** web server document root

Service Configuration:

* **Service Name:** `web-devops`
* **Type:** `NodePort`
* **NodePort:** `30008`

---

# Understanding the Core Idea

Before implementing the solution, it is important to understand how Kubernetes storage works.

A **PersistentVolume (PV)** represents a piece of storage available inside the cluster. This storage can come from many sources such as cloud disks, network storage, or a directory on a node. In this task the storage type used is **hostPath**, which simply means Kubernetes will use a directory that already exists on the node's filesystem.

A **PersistentVolumeClaim (PVC)** is a request for storage made by an application. Instead of the application knowing where storage physically exists, it simply asks Kubernetes for a certain amount of storage. Kubernetes then binds that claim to a suitable persistent volume.

The pod then mounts the PVC as a filesystem path inside the container, allowing the application to read and write files normally.

This design separates three responsibilities:

1. Infrastructure defines storage (PersistentVolume).
2. Application requests storage (PersistentVolumeClaim).
3. Pod consumes the storage.

---

# Step 1: Create the Persistent Volume

A persistent volume must first be created so that storage exists inside the cluster.

Create the following YAML file:

```bash
vi pv.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-devops
spec:
  storageClassName: manual
  capacity:
    storage: 4Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/dba
```

Explanation of important fields:

* **storageClassName: manual** means Kubernetes will not dynamically create storage. Instead the administrator manually provides the storage.
* **capacity: 4Gi** defines the maximum storage size available in this volume.
* **ReadWriteOnce** means the volume can be mounted by only one node at a time for reading and writing.
* **hostPath** tells Kubernetes to use a directory from the node filesystem. In this task the directory `/mnt/dba` already exists on the node.

Apply the configuration:

```bash
kubectl apply -f pv.yaml
```

Verify the persistent volume:

```bash
kubectl get pv
```

The status should appear as **Available**, meaning the storage is ready to be claimed.

---

# Step 2: Create the Persistent Volume Claim

Now the application requests storage using a PVC.

Create the claim configuration:

```bash
vi pvc.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-devops
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Explanation:

The claim asks Kubernetes for **1Gi** of storage. Since the persistent volume provides **4Gi**, Kubernetes binds the claim to the existing PV because it satisfies the requirements.

Apply the configuration:

```bash
kubectl apply -f pvc.yaml
```

Verify the claim:

```bash
kubectl get pvc
```

The status should become **Bound**, which means the claim is successfully attached to the persistent volume.

---

# Step 3: Create the Pod Using the Persistent Storage

Now create the application pod that will use the persistent storage.

Create the pod manifest:

```bash
vi pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-devops
  labels:
    app: web-devops
spec:
  containers:
  - name: container-devops
    image: nginx:latest
    volumeMounts:
    - name: devops-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: devops-storage
    persistentVolumeClaim:
      claimName: pvc-devops
```

Important parts:

* **nginx:latest** runs the Nginx web server.
* **mountPath /usr/share/nginx/html** is the document root where Nginx serves web content.
* **persistentVolumeClaim** connects the container to the previously created storage claim.

Apply the pod configuration:

```bash
kubectl apply -f pod.yaml
```

Verify pod creation:

```bash
kubectl get pods
```

The pod should reach the **Running** state.

---

# Step 4: Expose the Pod Using NodePort Service

A Kubernetes **Service** provides a stable network endpoint for accessing pods.

A **NodePort** service exposes the application on a fixed port on every node of the cluster.

Create the service configuration:

```bash
vi service.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-devops
spec:
  type: NodePort
  selector:
    app: web-devops
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30008
```

Since the pod must match the service selector, label the pod when creating it. If needed, the pod definition should include:

```yaml
labels:
  app: web-devops
```

Apply the service configuration:

```bash
kubectl apply -f service.yaml
```

Verify the service:

```bash
kubectl get svc
```

Expected output will show the NodePort **30008**.

---

# Testing the Web Server

Once the service is created, the web server can be accessed using the node's IP address and the assigned NodePort.

Example:

```
http://NODE-IP:30008
```

The default Nginx welcome page should appear, confirming that the pod and service are working correctly.

---

# Deep Understanding: Why Persistent Volumes Matter

Without persistent storage, every time a pod restarts the container filesystem resets to its original image state. Any files written by the application would disappear.

Persistent volumes solve this problem by storing data outside the container lifecycle. Even if the pod crashes, restarts, or gets rescheduled, Kubernetes reattaches the same storage to the new container.

This capability is critical for many real-world systems such as:

* Databases
* Content management systems
* File storage services
* Logging systems

Because of this design, Kubernetes applications remain both **stateless in deployment** and **stateful in storage**, allowing infrastructure to scale dynamically while preserving application data.

---

# Troubleshooting: 403 Forbidden from Nginx

While testing the service, the browser may display **403 Forbidden** instead of the Nginx welcome page. This situation often causes confusion because it appears as if the web server is not working. In reality, the Nginx server is running correctly, but it cannot read any web content from its document root.

The Nginx container serves web files from the directory:

```
/usr/share/nginx/html
```

Inside the container image, this directory normally contains a default file called **index.html**, which is the welcome page displayed when Nginx starts.

However, in this task the directory is mounted from the **PersistentVolume** using the PVC. When Kubernetes mounts a volume to a path inside a container, the mounted storage **replaces the original contents of that directory**. This means the default Nginx files that originally existed inside the image are no longer visible.

The PersistentVolume in this task uses a **hostPath** directory:

```
/mnt/dba
```

If this directory is empty, then the container's web root becomes empty as well. Since there is no **index.html** file and directory listing is disabled in Nginx by default, the web server returns the response:

```
403 Forbidden
```

---

# Quick Fix

The solution is simply to create an **index.html** file inside the mounted directory.

Access the running pod:

```bash
kubectl exec -it pod-devops -- bash
```

Create the web page file:

```bash
echo "Welcome to DevOps Web Server" > /usr/share/nginx/html/index.html
```

Exit the container:

```bash
exit
```

After creating this file, refresh the browser.

---

# Verify the Volume Mount

To confirm that the PersistentVolume is correctly mounted inside the container, list the files in the web root:

```bash
kubectl exec -it pod-devops -- ls /usr/share/nginx/html
```

If the directory was previously empty, it would show no files. After creating **index.html**, the file should appear in the listing.

---

# Expected Result

Once the **index.html** file exists inside the mounted volume, visiting the service endpoint will display the webpage instead of the error.

Example:

```
http://NODE-IP:30008
```

The browser should now display:

```
Welcome to DevOps Web Server
```

---

# Important Concept

Whenever a volume is mounted inside a container, the mounted storage completely **overrides the existing directory inside the container image**. Any files originally present in the container image at that location will disappear unless those files also exist in the mounted storage.

Because of this behavior, applications that depend on existing files (such as Nginx expecting `index.html`) may return errors if the mounted storage directory is empty.

Understanding this behavior is essential when designing Kubernetes workloads that rely on persistent storage.
