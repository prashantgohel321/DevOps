# Kubernetes Level 02 Day 11: Fix Issue with LAMP Environment

This document outlines the troubleshooting and resolution process for Kubernetes Level 02 Day 11. A WordPress application running on a LAMP stack inside a Kubernetes cluster stopped working after previously functioning correctly. Investigation revealed multiple configuration issues including incorrect service ports and application code referencing wrong environment variables.

---

## Table of Contents

- [Kubernetes Level 02 Day 11: Fix Issue with LAMP Environment](#kubernetes-level-02-day-11-fix-issue-with-lamp-environment)
  - [Table of Contents](#table-of-contents)
- [Task Overview](#task-overview)
- [Troubleshooting Process](#troubleshooting-process)
  - [1. Inspect Cluster Resources](#1-inspect-cluster-resources)
  - [2. Analyze Service Configuration](#2-analyze-service-configuration)
  - [3. Inspect Container Logs](#3-inspect-container-logs)
  - [4. Investigate Application Code](#4-investigate-application-code)
- [Step-by-Step Solution](#step-by-step-solution)
  - [1. Fix NodePort Configuration](#1-fix-nodeport-configuration)
  - [2. Identify Containers and Pod Name](#2-identify-containers-and-pod-name)
  - [3. Correct Environment Variable Usage in PHP](#3-correct-environment-variable-usage-in-php)
  - [4. Restart PHP Service](#4-restart-php-service)
  - [5. Verification](#5-verification)
- [Deep Dive: Debugging Multi-Container Pods](#deep-dive-debugging-multi-container-pods)
  - [Service Port Misconfiguration](#service-port-misconfiguration)
  - [Environment Variable Issues](#environment-variable-issues)
  - [Why Application-Level Debugging Matters](#why-application-level-debugging-matters)

---

# Task Overview

<a name="task-overview"></a>

**Objective:** Restore the functionality of the WordPress LAMP application deployed in Kubernetes.

The application was previously accessible but stopped working due to configuration and application-level issues.

**Deployment Details**

| Resource          | Name            |
| ----------------- | --------------- |
| Deployment        | `lamp-wp`       |
| Service           | `lamp-service`  |
| Database Service  | `mysql-service` |
| HTTP Port         | `80`            |
| Expected NodePort | `30008`         |

**Observed Problems**

1. The NodePort configured in the service was incorrect.
2. The application could not connect to the MySQL database.
3. The PHP application file referenced incorrect environment variable names.

---

# Troubleshooting Process

<a name="troubleshooting-process"></a>

## 1. Inspect Cluster Resources

<a name="1-inspect-cluster-resources"></a>

First, verify the running resources in the cluster.

```bash
kubectl get pods,deployments,services
```

Example output:

```
NAME                           READY   STATUS
pod/lamp-wp-5594699b75-67xrz   2/2     Running

NAME                      READY
deployment.apps/lamp-wp   1/1

NAME               TYPE       PORT(S)
lamp-service       NodePort   80:30009/TCP
mysql-service      ClusterIP  3306/TCP
```

Observation:

The NodePort was incorrectly set to **30009 instead of 30008**.

---

## 2. Analyze Service Configuration

<a name="2-analyze-service-configuration"></a>

Export the service configuration to a YAML file.

```bash
kubectl get svc lamp-service -o yaml > lamp-svc.yml
```

Edit the file:

```bash
vi lamp-svc.yml
```

Fix the following values:

```
nodePort: 30008
port: 80
targetPort: 80
```

Apply the changes.

```bash
kubectl apply -f lamp-svc.yml
```

Verify:

```bash
kubectl get svc
```

Expected output:

```
lamp-service   NodePort   80:30008/TCP
```

---

## 3. Inspect Container Logs

<a name="3-inspect-container-logs"></a>

The pod contains two containers:

* HTTP container (Apache + PHP)
* MySQL container

Retrieve the container names.

```bash
HTTP=$(kubectl get pod -o=jsonpath='{.items[*].spec.containers[0].name}')
MYSQL=$(kubectl get pod -o=jsonpath='{.items[*].spec.containers[1].name}')
POD=$(kubectl get pods -o=jsonpath='{.items[*].metadata.name}')
```

Check the HTTP container logs.

```bash
kubectl logs -f $POD -c $HTTP
```

Logs indicated that the application was failing to connect to the database.

---

## 4. Investigate Application Code

<a name="4-investigate-application-code"></a>

Access the HTTP container shell.

```bash
kubectl exec -it $POD -c $HTTP -- sh
```

Navigate to the application directory.

```bash
cd /app
ls
```

The main application file is:

```
index.php
```

Display the file.

```bash
cat index.php
```

Incorrect variables were found:

```php
$dbpass = $_ENV['MYSQL_PASSWORDS'];
$dbhost = $_ENV['HOST_MYQSL'];
```

These names do not match the environment variables provided by Kubernetes.

---

# Step-by-Step Solution

<a name="step-by-step-solution"></a>

## 1. Fix NodePort Configuration

<a name="1-fix-nodeport-configuration"></a>

Ensure the service exposes the correct port.

```bash
kubectl get svc lamp-service
```

Correct configuration:

```
80:30008/TCP
```

---

## 2. Identify Containers and Pod Name

<a name="2-identify-containers-and-pod-name"></a>

```bash
HTTP=$(kubectl get pod -o=jsonpath='{.items[*].spec.containers[0].name}')
MYSQL=$(kubectl get pod -o=jsonpath='{.items[*].spec.containers[1].name}')
POD=$(kubectl get pods -o=jsonpath='{.items[*].metadata.name}')
```

---

## 3. Correct Environment Variable Usage in PHP

<a name="3-correct-environment-variable-usage-in-php"></a>

Edit the PHP file.

```bash
vi /app/index.php
```

Fix the incorrect variables.

**Before**

```php
$dbpass = $_ENV['MYSQL_PASSWORDS'];
$dbhost = $_ENV['HOST_MYQSL'];
```

**After**

```php
$dbpass = $_ENV['MYSQL_PASSWORD'];
$dbhost = $_ENV['MYSQL_HOST'];
```

These variables correspond to the Kubernetes secrets injected into the pod.

---

## 4. Restart PHP Service

<a name="4-restart-php-service"></a>

Restart the PHP-FPM process inside the container.

```bash
service php-fpm restart
```

Verify status.

```bash
service php-fpm status
```

Expected output:

```
php-fpmd RUNNING
```

Exit the container.

```bash
exit
```

---

## 5. Verification

<a name="5-verification"></a>

Confirm environment variables inside both containers.

HTTP container:

```bash
kubectl exec -it $POD -c $HTTP -- env | grep -i mysql
```

MySQL container:

```bash
kubectl exec -it $POD -c $MYSQL -- env | grep -i mysql
```

Expected variables:

```
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
MYSQL_HOST
MYSQL_ROOT_PASSWORD
```

When accessing the application URL through the NodePort, the page should display:

```
Connected successfully
```

---

# Deep Dive: Debugging Multi-Container Pods

<a name="deep-dive-debugging-multi-container-pods"></a>

## Service Port Misconfiguration

A Kubernetes **NodePort service** exposes an application externally. If the NodePort is incorrect, traffic will never reach the application container.

Correct mapping:

```
NodePort → Service Port → Container Port
30008   → 80           → 80
```

---

## Environment Variable Issues

Applications often depend on environment variables injected by Kubernetes secrets or ConfigMaps.

Example:

```
MYSQL_HOST
MYSQL_USER
MYSQL_PASSWORD
MYSQL_DATABASE
```

If the application code references incorrect variable names, the connection to external services such as databases will fail even if the infrastructure is correct.

---

## Why Application-Level Debugging Matters

Many Kubernetes troubleshooting scenarios involve not only infrastructure configuration but also application logic.

Typical debugging workflow:

1. Verify Kubernetes resources.
2. Inspect service configuration.
3. Check container logs.
4. Inspect environment variables.
5. Debug application code inside the container.

This layered approach helps quickly isolate whether the issue is related to Kubernetes configuration or application behavior.

---
