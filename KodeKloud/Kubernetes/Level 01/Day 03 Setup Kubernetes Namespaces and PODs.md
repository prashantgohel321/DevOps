# Kubernetes Level 01 Day 03: Resource Isolation Using Namespaces and Targeted Pod Deployment

This document explains how a dedicated Namespace was created and how a Pod was deployed inside it. The purpose of this task is to understand logical isolation inside a Kubernetes cluster and to ensure that workloads are placed intentionally rather than relying on the default namespace.

The objective required the following:

* Namespace name: `dev`
* Pod name: `dev-nginx-pod`
* Image: `nginx:latest`

The important concept here is that namespaces act as isolation boundaries. Resources must be explicitly created inside them.

---

<br>
<br>

- [Kubernetes Level 01 Day 03: Resource Isolation Using Namespaces and Targeted Pod Deployment](#kubernetes-level-01-day-03-resource-isolation-using-namespaces-and-targeted-pod-deployment)
  - [Understanding Namespaces Before Creating Them](#understanding-namespaces-before-creating-them)
  - [Step 1: Create the Namespace](#step-1-create-the-namespace)
    - [Imperative Method](#imperative-method)
    - [Declarative Method (Infrastructure as Code)](#declarative-method-infrastructure-as-code)
  - [Step 2: Deploy the Pod Inside the Namespace](#step-2-deploy-the-pod-inside-the-namespace)
    - [Imperative Method](#imperative-method-1)
    - [Declarative Method](#declarative-method)
  - [Step 3: Verify Pod Placement and Status](#step-3-verify-pod-placement-and-status)
  - [Demonstrating Namespace Isolation Behavior](#demonstrating-namespace-isolation-behavior)
  - [Setting a Default Namespace for kubectl Context](#setting-a-default-namespace-for-kubectl-context)
  - [Deleting Resources](#deleting-resources)
  - [Internal Mechanics of Namespaces](#internal-mechanics-of-namespaces)
  - [Final State After Completion](#final-state-after-completion)


<br>
<br>

## Understanding Namespaces Before Creating Them

A Kubernetes cluster is shared infrastructure. Multiple teams, environments, or applications may run inside the same cluster. Without namespaces, all resources exist in a single global space, which leads to naming conflicts and management complexity.

Namespaces provide:

* Logical separation of resources
* Isolation of object names
* Independent management scope
* Foundation for resource quotas and access control

If no namespace is specified when creating resources, Kubernetes places them in the `default` namespace automatically.

---

<br>
<br>

## Step 1: Create the Namespace

Before deploying anything into `dev`, the namespace must exist.

### Imperative Method

```bash
kubectl create namespace dev
```

Expected output:

```
namespace/dev created
```

Verify namespace creation:

```bash
kubectl get namespaces

# OUTPUT

NAME                 STATUS   AGE
default              Active   30m
dev                  Active   83s
kube-node-lease      Active   30m
kube-public          Active   30m
kube-system          Active   30m
local-path-storage   Active   30m
```

You should see `dev` listed alongside default system namespaces such as `default`, `kube-system`, and `kube-public`.

---

<br>
<br>

### Declarative Method (Infrastructure as Code)

Create a YAML file.

```bash
vi namespace.yaml
```

Add the following content.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

Apply it:

```bash
kubectl apply -f namespace.yaml
```

Using YAML allows version control and reproducibility of environment setup.

---

<br>
<br>

## Step 2: Deploy the Pod Inside the Namespace

Once the namespace exists, the Pod must explicitly target it.

### Imperative Method

```bash
kubectl run dev-nginx-pod --image=nginx:latest -n dev

# OUTPUT
pod/dev-nginx-pod created
```

The `-n dev` flag tells the API server to create this Pod inside the `dev` namespace instead of `default`.

Internally, the API server stores this Pod object under the namespace key in etcd. Namespaces are implemented as logical prefixes in Kubernetes object storage.

---

<br>
<br>

### Declarative Method

Create a file named `dev-pod.yaml`.

```bash
vi dev-pod.yaml
```

Insert the following configuration.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dev-nginx-pod
  namespace: dev
spec:
  containers:
  - name: dev-nginx-container
    image: nginx:latest
```

Apply it:

```bash
kubectl apply -f dev-pod.yaml
```

By specifying `namespace: dev` under metadata, we bind the Pod to that namespace explicitly.

---

<br>
<br>

## Step 3: Verify Pod Placement and Status

If you check Pods without specifying namespace:

```bash
kubectl get pods
```

You may see no results because this command defaults to the `default` namespace.

Now check inside `dev`:

```bash
kubectl get pods -n dev
```

Expected output:

```
NAME             READY   STATUS    RESTARTS   AGE
dev-nginx-pod    1/1     Running   0          10s
```

To confirm deeper configuration:

```bash
kubectl describe pod dev-nginx-pod -n dev

# OUTPUT:

Name:             dev-nginx-pod
Namespace:        dev
Priority:         0
Service Account:  default
Node:             kodekloud-control-plane/172.17.0.2
Start Time:       Sat, 14 Feb 2026 05:17:47 +0000
Labels:           run=dev-nginx-pod
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:  10.244.0.5
Containers:
  dev-nginx-pod:
    Container ID:   containerd://95496463bc694e2548d58e088c1d8dfb433d08e2086b360b58d56ab5564ce577
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sat, 14 Feb 2026 05:17:55 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-x5sx2 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-x5sx2:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2m8s  default-scheduler  Successfully assigned dev/dev-nginx-pod to kodekloud-control-plane
  Normal  Pulling    2m8s  kubelet            Pulling image "nginx:latest"
  Normal  Pulled     2m1s  kubelet            Successfully pulled image "nginx:latest" in 7.061660581s (7.061676706s including waiting)
  Normal  Created    2m1s  kubelet            Created container dev-nginx-pod
  Normal  Started    2m    kubelet            Started container dev-nginx-pod
```

To check across all namespaces:

```bash
kubectl get pods -A

# OUTPUT:
NAMESPACE            NAME                                              READY   STATUS    RESTARTS   AGE
dev                  dev-nginx-pod                                     1/1     Running   0          2m42s
kube-system          coredns-5d78c9869d-6kxdw                          1/1     Running   0          31m
kube-system          coredns-5d78c9869d-zkz9q                          1/1     Running   0          31m
kube-system          etcd-kodekloud-control-plane                      1/1     Running   0          31m
kube-system          kindnet-k9xz4                                     1/1     Running   0          31m
kube-system          kube-apiserver-kodekloud-control-plane            1/1     Running   0          32m
kube-system          kube-controller-manager-kodekloud-control-plane   1/1     Running   0          31m
kube-system          kube-proxy-9m67t                                  1/1     Running   0          31m
kube-system          kube-scheduler-kodekloud-control-plane            1/1     Running   0          32m
local-path-storage   local-path-provisioner-6bc4bddd6b-sc5zh           1/1     Running   0          31m
```

This shows a cluster-wide view.

---

<br>
<br>

## Demonstrating Namespace Isolation Behavior

Try creating another Pod with the same name in the `default` namespace:

```bash
kubectl run dev-nginx-pod --image=nginx:latest
```

This will succeed because names are unique only within a namespace, not across the entire cluster.

Now verify:

```bash
kubectl get pods -A
```

You will observe two Pods with identical names but in different namespaces.

This proves that namespaces prevent naming collisions.

---

<br>
<br>

## Setting a Default Namespace for kubectl Context

To avoid using `-n dev` repeatedly, configure the current context.

```bash
kubectl config set-context --current --namespace=dev
```

Now run:

```bash
kubectl get pods
```

The command automatically queries the `dev` namespace.

To revert back:

```bash
kubectl config set-context --current --namespace=default
```

---

<br>
<br>

## Deleting Resources

To delete the Pod:

```bash
kubectl delete pod dev-nginx-pod -n dev
```

To delete the entire namespace:

```bash
kubectl delete namespace dev
```

Deleting a namespace removes all resources contained within it.

---

<br>
<br>

## Internal Mechanics of Namespaces

Namespaces do not create separate physical clusters. All resources still run on the same worker nodes. The isolation is logical and enforced by the API server.

Each object is stored under a namespace key in etcd. When queries are made, Kubernetes filters results based on namespace context.

Namespaces also serve as a boundary for:

* Resource quotas
* Network policies
* Role-Based Access Control (RBAC)

They are foundational for multi-tenant cluster environments.

---

<br>
<br>

## Final State After Completion

At the end of this setup:

* Namespace `dev` exists
* Pod `dev-nginx-pod` runs inside `dev`
* The image `nginx:latest` is deployed
* Isolation from the `default` namespace is confirmed
* Namespace context behavior is understood

This task establishes the foundation for environment separation inside Kubernetes clusters, which is essential for development, staging, and production segregation.
