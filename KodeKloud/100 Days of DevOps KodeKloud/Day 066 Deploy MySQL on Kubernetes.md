# DevOps Day 66: Deploying a Stateful Database on Kubernetes

Today's task was the most comprehensive Kubernetes deployment I've ever done. It was the complete, end-to-end process of deploying a **stateful application**—a MySQL database. This was a massive step up from the simple stateless web servers I've worked with before, as it required me to manage data persistence and sensitive secrets.

I had to create and connect five distinct Kubernetes objects: `Secrets` to hold passwords, a `PersistentVolume` (PV) to define the physical storage, a `PersistentVolumeClaim` (PVC) to request that storage, a `Deployment` to run the database, and a `Service` to expose it. This document is my very detailed, first-person guide to that entire process, written from the perspective of a Kubernetes beginner.

## Table of Contents
- [DevOps Day 66: Deploying a Stateful Database on Kubernetes](#devops-day-66-deploying-a-stateful-database-on-kubernetes)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [My Step-by-Step Solution](#my-step-by-step-solution)
      - [Phase 1: Creating the Secrets (Imperative Commands)](#phase-1-creating-the-secrets-imperative-commands)
      - [Phase 2: Writing the Manifest File (`mysql-app.yaml`)](#phase-2-writing-the-manifest-file-mysql-appyaml)
      - [Phase 3: Applying the Manifest and Verifying](#phase-3-applying-the-manifest-and-verifying)
    - [Why Did I Do This? (The "What \& Why" for a K8s Beginner)](#why-did-i-do-this-the-what--why-for-a-k8s-beginner)
    - [Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest](#deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest)
    - [Common Pitfalls for Beginners](#common-pitfalls-for-beginners)
    - [Exploring the Essential kubectl Commands](#exploring-the-essential-kubectl-commands)

---

### The Task
<a name="the-task"></a>
My objective was to deploy a MySQL database on Kubernetes with a complete stack of supporting resources. The specific requirements were:
1.  **Secrets:** Create three secrets: `mysql-root-pass` (for the root password), `mysql-db-url` (for the database name), and `mysql-user-pass` (for the application user's credentials).
2.  **PersistentVolume (PV):** Create `mysql-pv` with `250Mi` of `manual` storage using a `hostPath` at `/mnt/finance`.
3.  **PersistentVolumeClaim (PVC):** Create `mysql-pv-claim` to request `250Mi` of `manual` storage.
4.  **Deployment:** Create `mysql-deployment` with 1 replica using a `mysql` image. It needed to:
    -   Consume the secrets as environment variables (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`).
    -   Mount the PVC at the database's data path (`/var/lib/mysql`).
5.  **Service:** Create `mysql` as a `NodePort` service, exposing the database on node port `30007`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The solution required two phases: an *imperative* phase to safely create the secrets and a *declarative* phase to define the rest of the infrastructure.

#### Phase 1: Creating the Secrets (Imperative Commands)
I started by creating the secrets from the command line. This is the best practice as it prevents me from saving plain-text passwords in my YAML file.
```bash
# On the jump host:
# 1. Create the root password secret
kubectl create secret generic mysql-root-pass \
  --from-literal=password='YUIidhb667'

# 2. Create the user and password secret
kubectl create secret generic mysql-user-pass \
  --from-literal=username='kodekloud_sam' \
  --from-literal=password='LQfKeWWxWD'

# 3. Create the database name secret
kubectl create secret generic mysql-db-url \
  --from-literal=database='kodekloud_db2'
```

#### Phase 2: Writing the Manifest File (`mysql-app.yaml`)
I created a single YAML file to define all the other interconnected resources.
```yaml
# 1. The PersistentVolume (PV) - The "Supply" of Storage
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  storageClassName: manual
  capacity:
    storage: 250Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/finance"
---
# 2. The PersistentVolumeClaim (PVC) - The "Demand" for Storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
---
# 3. The Deployment - The Application Manager
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deployment
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql-container
          image: mysql:latest
          ports:
            - containerPort: 3306
          env:
            # Injecting the environment variables from the Secrets
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-root-pass
                  key: password
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: mysql-db-url
                  key: database
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-user-pass
                  key: username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-user-pass
                  key: password
          volumeMounts:
            # Mount the persistent storage into the container
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        # This volume links the Pod to the PersistentVolumeClaim
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: mysql-pv-claim
---
# 4. The Service - The Network Access Point
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: NodePort
  selector:
    app: mysql # This matches the Pod's label
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
      nodePort: 30007
```

#### Phase 3: Applying the Manifest and Verifying
1.  I applied the manifest to the cluster:
    ```bash
    kubectl apply -f mysql-app.yaml
    ```

2. I then verified that everything was created and connected: 
- `kubectl get secrets`: Confirmed my three secrets were created. 
- `kubectl get pv,pvc`: Showed both `mysql-pv` and `mysql-pv-claim` in the Bound state. 
- `kubectl get all`: Showed the `mysql-deployment` Pod Running, and the `mysql` Service was correctly exposing port 30007.

---

### Why Did I Do This? (The "What & Why" for a K8s Beginner)
<a name="why-did-i-do-this-the-what--why-for-a-k8s-beginner)"></a>

- **Stateful vs. Stateless**: A web server is "stateless"—I can delete it and create a new one without losing anything. A database is "stateful"—its entire purpose is to store data. If I delete the database Pod, the data must not be lost. This task was all about managing a stateful application.

- **Secret**: This is the correct way to handle sensitive data. I used kubectl create secret generic to create three of them. The official mysql image is smart; it's programmed to look for environment variables like MYSQL_ROOT_PASSWORD on its first run to automatically set itself up.

- **Persistent Storage (PV/PVC)**: This is the most important concept for stateful apps.

- **PersistentVolume (PV)**: I learned to think of this as the "supply" of storage. It's an administrator's job to define a piece of storage that is available to the cluster. In my case, I used hostPath to point to a directory on the server, but this could also be a cloud disk like an AWS EBS volume.

- **PersistentVolumeClaim (PVC)**: I learned to think of this as the "demand" for storage. An application (my Deployment) doesn't know or care about the physical storage. It just "claims" what it needs.

- **The Binding Process**: Kubernetes's magic is to automatically find a PV that matches the request from a PVC and "bind" them together.

- **The Pod volumes Section**: This is how the Pod gets the storage. The Pod's manifest says, "I need a volume, and the source for it is my claim named mysql-pv-claim." Kubernetes then mounts the bound PV into the container at the specified path (/var/lib/mysql), which is the exact location where MySQL stores its data.

---

### Deep Dive: A Line-by-Line Explanation of My Full-Stack YAML Manifest
<a name="deep-dive-a-line-by-line-explanation-of-my-full-stack-yaml-manifest"></a> My mysql-app.yaml file defined the four core components of a stateful service.

- **`kind`**: PersistentVolume (The "Supply")

- **`storageClassName: manual`**: I'm telling Kubernetes that I created this PV manually. It won't be automatically managed.
- **`
capacity: {storage: 250Mi}`**: Defining the total size of this storage.

- **`accessModes: [ReadWriteOnce]`**: Defines how the volume can be used. ReadWriteOnce (RWO) means it can only be mounted as read-write by a single Node at a time. This is standard for a database.

- **`hostPath: {path: "/mnt/finance"}`**: Defines the type of storage. It's a simple directory on the host machine.

- **`kind`**: PersistentVolumeClaim (The "Demand")

- **`storageClassName: manual:`** This must match the storageClassName of the PV I want to bind to.

- **`accessModes: [ReadWriteOnce]`**: This must also match the PV.

- **`resources: {requests: {storage: 250Mi}}`**: I am requesting 250Mi of storage. Kubernetes will find a PV that can satisfy this request.

- **`kind`**: Deployment (The Application)

- **`replicas: 1:`** A database can't typically be scaled this way, so 1 replica is correct.

- **`selector: {matchLabels: {app: mysql}}`**: The "glue" that connects this Deployment to its Pods.

- **`template: {metadata: {labels: {app: mysql}}}`**: The "blueprint" for the Pods, giving them the label that the Deployment (and the Service) will look for.

- **`env:`**: This is where I defined the environment variables for the MySQL container.

- **`valueFrom: {secretKeyRef: ...}`**: This is the most secure part. Instead of a plain-text value:, I'm telling the container, "Go to the Secret named mysql-root-pass and get the value from the key named password."

- **`volumeMounts:`**: This tells the container where to mount the storage inside its filesystem.

- **`volumes:`**: This is at the Pod level. It defines the mysql-persistent-storage volume and links it to my PersistentVolumeClaim by its claimName.

- **`kind`**: Service (The Network)

- **`type: NodePort`**: Exposes the service on a static port on the host Node.

- **`selector: {app: mysql}`**: The crucial link. This tells the Service to send traffic to any Pod with the label app: mysql.

- **`port: 3306`**: The port the Service listens on inside the cluster.

- **`targetPort: 3306`**: The port the container is listening on.

- **`nodePort: 30007`**: The static port opened on the Node for external access.

---

### Common Pitfalls for Beginners
<a name="common-pitfalls-for-beginners"></a>

- **Pending PVC**: A PersistentVolumeClaim that is stuck in a Pending state is the most common storage problem. It almost always means Kubernetes couldn't find a PersistentVolume that matched its requirements (either the storageClassName was wrong, the accessModes were incompatible, or no PV had enough capacity).

- **CrashLoopBackOff Pod**: My Pod could have gotten stuck in a crash loop if I had made a typo in the secret names. The MySQL image, upon starting, would look for the MYSQL_ROOT_PASSWORD environment variable. If it was missing, the process would fail, exit, and Kubernetes would restart it, creating an endless loop.

- **emptyDir for Databases**: The task specifically uses an emptyDir for the database. In a real-world scenario, this would be a terrible idea, as all data would be lost if the Pod restarted. My use of hostPath for the PV is a step up, but the true professional solution is to use a cloud-specific storage class (like aws-ebs-sc) that can dynamically provision a persistent disk.

---

### Exploring the Essential kubectl Commands
<a name="exploring-the-essential-kubectl-commands"></a>

- **`kubectl create secret generic [name] --from-literal=[key]=[value]`**: The imperative command to quickly create a secret from plain text on the command line. This is much safer than writing a YAML manifest for secrets and saving passwords in your code.

- **`kubectl apply -f [filename.yaml]`**: The standard way to create or update all the resources from my manifest file.

- **`kubectl get all`**: A great command to get a quick overview of all the major resources (Pods, Deployments, Services, etc.).

- **`kubectl get pv`**: Lists all PersistentVolumes in the cluster and their status (e.g., Available or Bound).

- **`kubectl get pvc`**: Lists all PersistentVolumeClaims and their status (e.g., Pending or Bound).

- **`kubectl describe pod [pod-name]`**: My primary tool for troubleshooting a Pending or CrashLoopBackOff Pod. The Events section at the bottom would tell me if a volume failed to mount or if the container failed its startup.