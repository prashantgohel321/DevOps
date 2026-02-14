# Kubernetes Level 01 Day 04: Controlling Resource Usage with Requests and Limits

This document explains how to define CPU and memory constraints for a Kubernetes Pod in order to control resource consumption and prevent one workload from affecting others in the cluster. The objective was to create a Pod running the `httpd:latest` image while enforcing specific CPU and memory requests and limits.

The required configuration is:

* Pod Name: `httpd-pod`
* Container Name: `httpd-container`
* Image: `httpd:latest`
* Memory Request: 15Mi
* CPU Request: 100m
* Memory Limit: 20Mi
* CPU Limit: 100m

This task introduces the concept of resource guarantees and enforcement inside Kubernetes.

---

<br>
<br>

- [Kubernetes Level 01 Day 04: Controlling Resource Usage with Requests and Limits](#kubernetes-level-01-day-04-controlling-resource-usage-with-requests-and-limits)
  - [Why Resource Limits Matter Before Writing YAML](#why-resource-limits-matter-before-writing-yaml)
  - [Step 1: Create the Pod Manifest with Resource Definitions](#step-1-create-the-pod-manifest-with-resource-definitions)
  - [Understanding the resources Section](#understanding-the-resources-section)
    - [Requests](#requests)
    - [Limits](#limits)
  - [Step 2: Apply the Configuration](#step-2-apply-the-configuration)
  - [Step 3: Verify Resource Configuration and Status](#step-3-verify-resource-configuration-and-status)
  - [Monitoring Resource Consumption](#monitoring-resource-consumption)
  - [What Happens Internally When Limits Are Reached](#what-happens-internally-when-limits-are-reached)
  - [Quality of Service (QoS) Classes](#quality-of-service-qos-classes)
  - [Demonstrating Scheduling Behavior](#demonstrating-scheduling-behavior)
  - [Updating Resource Limits](#updating-resource-limits)
  - [Cleanup](#cleanup)
  - [Final State After Completion](#final-state-after-completion)


<br>
<br>

## Why Resource Limits Matter Before Writing YAML

In a shared Kubernetes cluster, multiple Pods run on the same worker nodes. Each node has finite CPU and memory. If workloads are not controlled, one container may consume excessive memory or CPU, affecting other applications. This situation is commonly referred to as a noisy neighbor problem.

Kubernetes prevents this by using:

* Requests: Used by the scheduler to decide where a Pod can run
* Limits: Enforced by the container runtime to cap usage

Without requests and limits, scheduling decisions are less precise and runtime enforcement is not applied.

---

<br>
<br>

## Step 1: Create the Pod Manifest with Resource Definitions

Create a YAML file named `pod.yaml`.

```bash
vi pod.yaml
```

Insert the following configuration.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: httpd-pod
spec:
  containers:
  - name: httpd-container
    image: httpd:latest
    resources:
      requests:
        memory: "15Mi"
        cpu: "100m"
      limits:
        memory: "20Mi"
        cpu: "100m"
```

---

<br>
<br>

## Understanding the resources Section

Under the container specification, the `resources` block defines how Kubernetes should treat this workload.

### Requests

Requests represent the minimum resources the container is expected to need.

* Memory request of 15Mi means the scheduler will only place the Pod on a node that has at least 15Mi of free allocatable memory.
* CPU request of 100m means 100 millicores, which equals 0.1 CPU core.

The scheduler uses these values to make placement decisions.

### Limits

Limits define the maximum amount of resources the container is allowed to consume.

* Memory limit of 20Mi means if the container attempts to use more than 20Mi, it will be terminated with an Out Of Memory (OOM) event.
* CPU limit of 100m means the container cannot exceed 0.1 CPU core. If it attempts to use more, it will be throttled.

Requests influence scheduling. Limits influence runtime enforcement.

---

<br>
<br>

## Step 2: Apply the Configuration

Create the Pod in the cluster.

```bash
kubectl apply -f pod.yaml
```

Expected output:

```
pod/httpd-pod created
```

Kubernetes now stores the desired state in etcd, and the scheduler evaluates node availability based on the defined requests.

---

<br>
<br>

## Step 3: Verify Resource Configuration and Status

Check Pod status:

```bash
kubectl get pods
```

Wait until the status becomes `Running`.

To confirm resource values were applied correctly:

```bash
kubectl describe pod httpd-pod
```

Inside the `Containers` section, verify:

```
Limits:
  cpu:     100m
  memory:  20Mi
Requests:
  cpu:     100m
  memory:  15Mi
```

To inspect using structured output:

```bash
kubectl get pod httpd-pod -o jsonpath='{.spec.containers[0].resources}'
```

---

<br>
<br>

## Monitoring Resource Consumption

If metrics-server is installed, view live usage:

```bash
kubectl top pod httpd-pod
```

This displays current CPU and memory consumption, allowing comparison against limits.

---

<br>
<br>

## What Happens Internally When Limits Are Reached

CPU limits are enforced using Linux control groups (cgroups). When CPU usage exceeds the defined limit, the kernel throttles execution time. The container continues running but cannot consume more CPU cycles than allowed.

Memory limits are also enforced by cgroups. If the container attempts to allocate memory beyond its limit, the kernel triggers an Out Of Memory kill event. Kubernetes marks the Pod as `OOMKilled` and restarts the container depending on restart policy.

You can inspect events with:

```bash
kubectl describe pod httpd-pod
```

Look for `OOMKilled` under container state if the memory limit is exceeded.

---

<br>
<br>

## Quality of Service (QoS) Classes

Kubernetes assigns each Pod a QoS class based on requests and limits.

* Guaranteed: Requests equal limits for all containers
* Burstable: Requests defined but not equal to limits
* BestEffort: No requests or limits defined

In this configuration, CPU request equals CPU limit, but memory request is less than memory limit. Therefore, the Pod receives the Burstable QoS class.

Check QoS class:

```bash
kubectl get pod httpd-pod -o jsonpath='{.status.qosClass}'
```

QoS affects eviction priority during node pressure situations.

---

<br>
<br>

## Demonstrating Scheduling Behavior

To inspect node allocatable resources:

```bash
kubectl describe node <node-name>
```

Under the Allocatable section, you can observe total CPU and memory available for scheduling. Requests subtract from this allocatable pool when Pods are scheduled.

---

<br>
<br>

## Updating Resource Limits

If changes are needed, edit the Pod.

```bash
kubectl edit pod httpd-pod
```

Standalone Pods cannot update resource fields without recreation. In real environments, resource adjustments are typically managed through Deployments instead of direct Pod definitions.

---

<br>
<br>

## Cleanup

To remove the Pod:

```bash
kubectl delete pod httpd-pod
```

---

<br>
<br>

## Final State After Completion

At the end of this task:

* The Pod `httpd-pod` is running
* CPU request and limit are set to 100m
* Memory request is 15Mi
* Memory limit is 20Mi
* The scheduler used requests for placement
* The runtime enforces limits via cgroups

This task establishes an essential principle in Kubernetes operations: defining resource boundaries is necessary to maintain predictable, stable, and fair cluster behavior.
