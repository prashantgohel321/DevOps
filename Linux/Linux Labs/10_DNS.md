# Linux Lab 10: Configuring DNS Resolution

This lab focuses on how Linux systems resolve hostnames to IP addresses. We explore the three critical configuration files that control this process: `/etc/resolv.conf`, `/etc/hosts`, and `/etc/nsswitch.conf`.

[Image of Linux DNS resolution flow]

## Table of Contents
- [Linux Lab 10: Configuring DNS Resolution](#linux-lab-10-configuring-dns-resolution)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Identifying the DNS Server](#1-identifying-the-dns-server)
      - [2. Understanding Local Host Resolution (/etc/hosts)](#2-understanding-local-host-resolution-etchosts)
      - [3. DNS Configuration File](#3-dns-configuration-file)
      - [4. Changing the DNS Server](#4-changing-the-dns-server)
      - [5. Checking Resolution Order](#5-checking-resolution-order)
      - [6. Modifying Resolution Order](#6-modifying-resolution-order)
      - [7. Understanding Search Domains](#7-understanding-search-domains)
    - [Configuration File Reference](#configuration-file-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **DNS (Domain Name System):** The system that translates human-readable domain names (like `google.com`) into IP addresses (like `142.250.190.78`).
* **`/etc/resolv.conf`:** The primary configuration file for the DNS resolver. It tells the system which external DNS server to ask for IP addresses.
* **`/etc/hosts`:** A local file that maps hostnames to IP addresses manually. It's like a personal, local phonebook that overrides DNS.
* **`/etc/nsswitch.conf` (Name Service Switch):** This file determines the *order* in which the system looks for information. It decides whether to check `/etc/hosts` ("files") first or ask the DNS server ("dns") first.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Identifying the DNS Server
<a name="1-identifying-the-dns-server"></a>
**Question:** What is the IP address of the DNS Server used in this system?
**Answer:** `127.0.0.11`

**Explanation:**
We inspected the resolver configuration file:
```bash
cat /etc/resolv.conf
# Output:
# search caleston.ca
# nameserver 127.0.0.11
# options ndots:5
```
The line `nameserver 127.0.0.11` indicates the IP address the system queries for DNS lookups.

#### 2. Understanding Local Host Resolution (/etc/hosts)
<a name="2-understanding-local-host-resolution-etc-hosts"></a>
**Question:** Which file is responsible for host file-based DNS resolution?
**Answer:** `/etc/hosts`

**Explanation:**
We checked the file content:
```bash
cat /etc/hosts
```
**Analyzing the Output:**
* `127.0.0.1 localhost`: Standard loopback entry.
* `172.16.238.10 devapp01`: Maps the name `devapp01` to the IP `172.16.238.10`.
* `172.16.239.10 devdb01`: Maps `devdb01` to its IP.
This file allows the system to resolve these names locally without needing to ask an external DNS server.

#### 3. DNS Configuration File
<a name="3-dns-configuration-file"></a>
**Question:** What is the configuration file used for the DNS Server?
**Answer:** `/etc/resolv.conf`

**Explanation:**
As seen in step 1, this file configures the resolver library, specifying nameservers and search domains.

#### 4. Changing the DNS Server
<a name="4-changing-the-dns-server"></a>
**Task:** Change the DNS Server to Google's DNS (8.8.8.8).

**Steps:**
1.  Switch to root user: `sudo su` (Password: `caleston123`)
2.  Edit the file: `vi /etc/resolv.conf` (or use `nano` or `sed`)
3.  Change `nameserver 127.0.0.11` to `nameserver 8.8.8.8`.

**Command (One-liner):**
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```
*(Note: In a real persistent environment, `echo >` overwrites the file. If you wanted to keep other settings like `search`, you would edit it manually.)*

#### 5. Checking Resolution Order
<a name="5-checking-resolution-order"></a>
**Question:** What is the current order utilized by the system to resolve an IP address?
**Answer:** `files dns` (Hosts file first, then DNS)

**Explanation:**
We checked `/etc/nsswitch.conf`:
```bash
grep hosts /etc/nsswitch.conf
# Output: hosts:          files dns
```
* **files:** Refers to `/etc/hosts`.
* **dns:** Refers to the nameserver in `/etc/resolv.conf`.
This means the system checks the local file *first*.

#### 6. Modifying Resolution Order
<a name="6-modifying-resolution-order"></a>
**Task:** Change the order to DNS first and then hosts.

**Steps:**
1.  Switch to root (`sudo su`).
2.  Edit `/etc/nsswitch.conf`.
3.  Find the line `hosts: files dns`.
4.  Change it to `hosts: dns files`.

**Why do this?**
Sometimes you want the central DNS server to be the source of truth, overriding any stale entries in a local `/etc/hosts` file.

#### 7. Understanding Search Domains
<a name="7-understanding-search-domains"></a>
**Question:** Which search domain is configured in this system?
**Answer:** `caleston.ca`

**Explanation:**
We inspected `/etc/resolv.conf`:
```bash
cat /etc/resolv.conf
# Output: search caleston.ca
```
**What does this mean?**
If you try to `ping server1`, the system will automatically try to resolve `server1.caleston.ca`. It saves you from typing the full domain name for servers inside your own network.

---

### Configuration File Reference
<a name="configuration-file-reference"></a>

| File | Purpose | Key Directive |
| :--- | :--- | :--- |
| `/etc/resolv.conf` | Configures DNS resolver | `nameserver` (DNS IP), `search` (Default domain) |
| `/etc/hosts` | Local hostname-to-IP mapping | `IP_address hostname` |
| `/etc/nsswitch.conf` | Determines lookup order | `hosts: files dns` |

   