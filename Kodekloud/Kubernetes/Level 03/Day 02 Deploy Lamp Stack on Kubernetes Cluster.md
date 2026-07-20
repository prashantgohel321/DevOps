# Kubernetes Level 03 Day 02: Deploy LAMP Stack on Kubernetes Cluster

This document outlines the solution for Kubernetes Level 03 Day 02. The objective was to provision a dynamic PHP website backed by a MySQL database, all running within a single multi-container Pod (the LAMP stack).

## Table of Contents
- [Kubernetes Level 03 Day 02: Deploy LAMP Stack on Kubernetes Cluster](#kubernetes-level-03-day-02-deploy-lamp-stack-on-kubernetes-cluster)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Create the ConfigMap](#1-create-the-configmap)
    - [2. Define the Unified Manifest](#2-define-the-unified-manifest)
    - [3. Deploy the PHP Application](#3-deploy-the-php-application)
    - [4. Verification](#4-verification)
  - [Deep Dive: Multi-Container Architectures](#deep-dive-multi-container-architectures)
    - [Shared Network Namespace](#shared-network-namespace)
    - [ConfigMap Mounting with `subPath`](#configmap-mounting-with-subpath)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy a WordPress-ready LAMP stack using Kubernetes native objects.

* **Deployment Name:** `lamp-wp`
* **Containers:** * `httpd-php-container`: `webdevops/php-apache:alpine-3-php7`
    * `mysql-container`: `mysql:5.6`
* **ConfigMap:** `php-config` (sets `variables_order = "EGPCS"`)
* **Services:**
    * `lamp-service`: NodePort `30008` (HTTP)
    * `mysql-service`: Port `3306` (Internal)
* **Secrets Handling:** Pull database credentials from existing secrets into environment variables for both containers.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Create the ConfigMap
<a name="1-create-the-configmap"></a>
PHP needs the `variables_order` set to "EGPCS" to ensure it correctly populates the `$_ENV` superglobal from environment variables.

**Command:**
```bash
kubectl create configmap php-config --from-literal=php.ini='variables_order = "EGPCS"'
```

### 2. Define the Unified Manifest
<a name="2-define-the-unified-manifest"></a>
We will create a YAML file defining the Deployment and both Services.

Create generic secret:
```bash
kubectl create secret generic database \
--from-literal=MYSQL_ROOT_PASSWORD=admin123 \
--from-literal=MYSQL_DATABASE=kodekloud \
--from-literal=MYSQL_USER=kodekloud \
--from-literal=MYSQL_PASSWORD=admin123 \
--from-literal=MYSQL_HOST=mysql-service
```


Edit index.php file:
```php
<?php
$dbname = $_ENV["MYSQL_DATABASE"];
$dbuser = $_ENV["MYSQL_USER"];
$dbpass = $_ENV["MYSQL_PASSWORD"];
$dbhost = $_ENV["MYSQL_HOST"];

$connect = mysqli_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to '$dbhost'");

$test_query = "SHOW TABLES FROM $dbname";
$result = mysqli_query($test_query);

if ($result->connect_error) {
   die("Connection failed: " . $conn->connect_error);
}
  echo "Connected successfully";
```

**Command:**
```bash
vi lamp-stack.yaml
```

**Content:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lamp-wp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lamp-app
  template:
    metadata:
      labels:
        app: lamp-app
    spec:
      volumes:
      - name: php-config-volume
        configMap:
          name: php-config
      containers:
      - name: httpd-php-container
        image: webdevops/php-apache:alpine-3-php7
        ports:
        - containerPort: 80
        volumeMounts:
        - name: php-config-volume
          mountPath: /opt/docker/etc/php/php.ini
          subPath: php.ini
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom: { secretKeyRef: { name: mysql-root-pass, key: password } }
        - name: MYSQL_DATABASE
          valueFrom: { secretKeyRef: { name: mysql-db-url, key: database } }
        - name: MYSQL_USER
          valueFrom: { secretKeyRef: { name: mysql-user-pass, key: username } }
        - name: MYSQL_PASSWORD
          valueFrom: { secretKeyRef: { name: mysql-user-pass, key: password } }
        - name: MYSQL_HOST
          valueFrom: { secretKeyRef: { name: mysql-host, key: host } }

      - name: mysql-container
        image: mysql:5.6
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom: { secretKeyRef: { name: mysql-root-pass, key: password } }
        - name: MYSQL_DATABASE
          valueFrom: { secretKeyRef: { name: mysql-db-url, key: database } }
        - name: MYSQL_USER
          valueFrom: { secretKeyRef: { name: mysql-user-pass, key: username } }
        - name: MYSQL_PASSWORD
          valueFrom: { secretKeyRef: { name: mysql-user-pass, key: password } }
        - name: MYSQL_HOST
          valueFrom: { secretKeyRef: { name: mysql-host, key: host } }
---
apiVersion: v1
kind: Service
metadata:
  name: lamp-service
spec:
  type: NodePort
  selector:
    app: lamp-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30008
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: lamp-app
  ports:
    - port: 3306
      targetPort: 3306
```

**Apply:**
```bash
kubectl apply -f lamp-stack.yaml
```

### 3. Deploy the PHP Application
<a name="3-deploy-the-php-application"></a>
Copy the provided `index.php` from the jump host into the running container's document root (`/app`).

**Command:**
```bash
kubectl cp /tmp/index.php lamp-wp-<POD_ID>:/app/index.php -c httpd-php-container
```

*Note: Ensure the `index.php` utilizes `getenv('MYSQL_USER')` etc., rather than hardcoded strings.*

### 4. Verification
<a name="4-verification"></a>
Verify the pods are running and test the database connection.

**Check Status:**
```bash
kubectl get pods
# Wait for 2/2 READY
```

**Test Accessibility:**
Open the web browser and access the NodePort `30008`.
* **Expected Result:** "Connected successfully"

---

## Deep Dive: Multi-Container Architectures
<a name="deep-dive-multi-container-architectures"></a>

### Shared Network Namespace
In this task, MySQL and Apache/PHP reside in the **same Pod**. 
* **Networking:** They share the same IP address and `localhost` interface.
* **Connectivity:** Even though we created a `mysql-service`, the PHP application should ideally connect to `127.0.0.1:3306`. If the `MYSQL_HOST` secret points to the service name, Kubernetes DNS handles the resolution, but `localhost` is more efficient for intra-pod communication.

### ConfigMap Mounting with `subPath`
When mounting a ConfigMap to a path that already contains files (like `/opt/docker/etc/php/`), using a standard mount would overwrite the entire directory, potentially deleting other configuration files.
* **`subPath`**: By specifying `subPath: php.ini`, we only project that single specific file into the directory, leaving the rest of the target folder's contents intact.
  