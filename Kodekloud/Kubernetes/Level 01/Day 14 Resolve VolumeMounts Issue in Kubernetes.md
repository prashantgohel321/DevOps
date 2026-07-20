# Kubernetes Level 01 – Day 14: Resolve VolumeMounts Issue

This document explains how to troubleshoot and fix a multi-container Pod where shared volume mount paths were misconfigured. The application stack consists of Nginx and PHP-FPM running inside the same Pod, sharing a volume for application files.

---

<br>
<br>

- [Kubernetes Level 01 – Day 14: Resolve VolumeMounts Issue](#kubernetes-level-01--day-14-resolve-volumemounts-issue)
  - [Objective](#objective)
- [Understanding the Architecture](#understanding-the-architecture)
- [Troubleshooting Process](#troubleshooting-process)
  - [Step 1: Check Pod Status](#step-1-check-pod-status)
  - [Step 2: Inspect Configuration](#step-2-inspect-configuration)
- [Root Cause](#root-cause)
- [Step-by-Step Solution](#step-by-step-solution)
  - [1. Extract Pod Configuration](#1-extract-pod-configuration)
  - [2. Fix the VolumeMount](#2-fix-the-volumemount)
  - [3. Replace the Pod](#3-replace-the-pod)
  - [4. Copy the PHP File](#4-copy-the-php-file)
- [Internal Working of Shared Volumes](#internal-working-of-shared-volumes)
- [Why Mount Paths Must Match](#why-mount-paths-must-match)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Fix the volume mount configuration of the Pod `nginx-phpfpm` and deploy a PHP file so the application becomes accessible.

* **Pod Name:** `nginx-phpfpm`
* **Containers:**

  * `nginx-container`
  * `php-fpm-container`
* **ConfigMap:** `nginx-config`
* **Final Action:** Copy `/home/thor/index.php` into the shared document root

---

<br>
<br>

# Understanding the Architecture

This Pod uses two containers:

1. Nginx → Handles HTTP requests
2. PHP-FPM → Executes PHP scripts

Both containers must access the same application files. This is achieved through a shared volume.

If the mount paths are inconsistent between containers, the application will fail even if the Pod status is `Running`.

---

<br>
<br>

# Troubleshooting Process

## Step 1: Check Pod Status

```bash
kubectl get pods
```

The Pod shows `2/2 Running`. This indicates containers are alive, but not necessarily functioning correctly.

---

<br>
<br>

## Step 2: Inspect Configuration

```bash
kubectl describe pod nginx-phpfpm
```

Observe volume mounts:

* `php-fpm-container` mounted at `/var/www/html`
* `nginx-container` mounted at `/usr/share/nginx/html`

This mismatch causes application path resolution errors.

---

<br>
<br>

# Root Cause

When Nginx forwards a PHP request, it passes the file path to PHP-FPM (for example `/var/www/html/index.php`).

If Nginx stores files under `/usr/share/nginx/html` but PHP-FPM expects them under `/var/www/html`, the file cannot be found.

Even though both containers share the same underlying volume, incorrect mount paths break logical consistency.

---

<br>
<br>

# Step-by-Step Solution

## 1. Extract Pod Configuration

Pods cannot have volume mounts modified directly. Export the YAML first.

```bash
kubectl get pod nginx-phpfpm -o yaml > pod.yaml
```

---

<br>
<br>

## 2. Fix the VolumeMount

Edit the YAML file:

```bash
vi pod.yaml
```

Locate the `volumeMounts` section under `nginx-container`.

Incorrect:

```yaml
- mountPath: /usr/share/nginx/html
  name: shared-files
```

Correct it to:

```yaml
- mountPath: /var/www/html
  name: shared-files
```

Ensure that both containers now mount the shared volume at `/var/www/html`.

Remove auto-generated metadata fields if necessary.

---

<br>
<br>

## 3. Replace the Pod

Recreate the Pod with corrected configuration:

```bash
kubectl replace --force -f pod.yaml
```

Wait until:

```bash
kubectl get pods
```

Shows the Pod in `Running` state.

---

<br>
<br>

## 4. Copy the PHP File

Once the volume paths match, copy the PHP file into the shared document root.

```bash
kubectl cp /home/thor/index.php \
  nginx-phpfpm:/var/www/html/index.php \
  -c nginx-container
```

Since the volume is shared, PHP-FPM can now access the same file.

---

<br>
<br>

# Internal Working of Shared Volumes

A shared volume inside a Pod:

* Exists at Pod level
* Is mounted into multiple containers
* Provides shared filesystem access

The physical data location is the same. Only the mount path inside each container determines how it appears in that container’s filesystem.

---

<br>
<br>

# Why Mount Paths Must Match

Nginx configuration usually defines a root directory and passes script execution paths to PHP-FPM using FastCGI.

Example:

If Nginx sends:

```text
SCRIPT_FILENAME=/var/www/html/index.php
```

Then PHP-FPM must have that exact path available locally.

If paths differ:

* Nginx might see file under `/usr/share/nginx/html`
* PHP-FPM looks under `/var/www/html`
* Result → "Primary script unknown" or 404 errors

Consistency in mount paths ensures both containers refer to identical filesystem locations.

---

<br>
<br>

# Key Outcome

The `nginx-phpfpm` Pod is corrected. Both containers now share the volume at the same mount path. The `index.php` file is accessible, and the application loads successfully.
