# Linux Lab 1: Securing Infrastructure with IPTables

This lab focused on securing a development environment consisting of a web server (`devapp01`) and a database server (`devdb01`) using `iptables`. The goal was to implement a strict firewall policy that allows only necessary traffic while blocking everything else.

This document details the step-by-step process, the challenges encountered (specifically with DNS resolution for the final task), and the solutions applied.

## Table of Contents
- [Linux Lab 1: Securing Infrastructure with IPTables](#linux-lab-1-securing-infrastructure-with-iptables)
  - [Table of Contents](#table-of-contents)
    - [Architecture Overview](#architecture-overview)
    - [Step-by-Step Implementation](#step-by-step-implementation)
      - [1. Installation \& Initial Check](#1-installation--initial-check)
      - [2. Securing Incoming Traffic (INPUT Chain)](#2-securing-incoming-traffic-input-chain)
      - [3. Securing Outgoing Traffic (OUTPUT Chain)](#3-securing-outgoing-traffic-output-chain)
      - [4. The Google HTTPS Challenge (DNS \& Rule Insertion)](#4-the-google-https-challenge-dns--rule-insertion)
    - [Key Concepts \& Lessons Learned](#key-concepts--lessons-learned)
    - [Command Reference](#command-reference)

---

<br>
<br>

### Architecture Overview
<a name="architecture-overview"></a>
The environment consists of three main components:
1.  **Web Server (`devapp01`):** Hosts the application. Needs to talk to the DB server and an external repo.
2.  **Database Server (`devdb01`):** Hosts the database (PostgreSQL).
3.  **Software Repository (`caleston-repo-01`):** An internal server for software updates.


**Connectivity Requirements:**
-   **Bob's Laptop (172.16.238.187)** must have SSH and HTTP access to the Web Server.
-   **Web Server (`devapp01`)** must access:
    -   PostgreSQL (5432) on `devdb01` (172.16.238.11).
    -   HTTP (80) on `caleston-repo-01` (172.16.238.15).
    -   HTTPS (443) on `google.com`.

---

<br>
<br>

### Step-by-Step Implementation
<a name="step-by-step-implementation"></a>

#### 1. Installation & Initial Check
<a name="1-installation--initial-check"></a>
First, `iptables` was installed on both servers.
```bash
sudo apt update
sudo apt install iptables -y
```
I verified that no existing rules were present to ensure a clean slate.
```bash
sudo iptables -L
# Output showed empty chains (INPUT, FORWARD, OUTPUT) with policy ACCEPT.
```

`apt` and `apt-get`: `apt` and `apt-get` both are **package management** commands in **Debian/Ubuntu** systems.
- `apt-get` → older, low-level tool used mainly by scripts.
- `apt` → newer, user-friendly command for humans.

`sudo apt iptables -L` Breakdown:
- `sudo` → run as admin
- `iptables` → Linux firewall tool
- `-L` → list all current firewall rules (INPUT, OUTPUT, FORWARD)

`iptables`: a tool in Linux that controls the system’s firewall rules.
- It decides which **network traffic** is allowed and which traffic is blocked, based on rules you set.

Three default chains:
1. **INPUT**: Rules for traffic coming into your machine. (Example: someone `SSH’ing` into your server.)
2. **Output**: Rules for traffic going out from your machine. (Example: your server sending a request to another server.)
3. **FORWARD**: Rules for traffic passing through your machine. (Example: when your server is acting like a router/firewall and forwarding packets.)

<br>
<br>

#### 2. Securing Incoming Traffic (INPUT Chain)
<a name="2-securing-incoming-traffic-input-chain"></a>
The strategy for incoming traffic is **"Allow specific, then block everything else."**

1.  **Allow SSH and HTTP from Bob's Laptop:** This was critical to do *first* to avoid locking myself out of the SSH session.
    ```bash
    # Allow SSH (port 22) only from 172.16.238.187.
    sudo iptables -A INPUT -p tcp -s 172.16.238.187 --dport 22 -j ACCEPT

    # Allow HTTP (port 80) only from 172.16.238.187.
    sudo iptables -A INPUT -p tcp -s 172.16.238.187 --dport 80 -j ACCEPT
    ```

**Command breakdown:**
- `-A INPUT` → add a new rule to the INPUT chain
- `-p tcp` → match TCP protocol
- `-s 172.16.238.187` → allow only this source IP
- `--dport 22` → match destination port 22 (SSH)
- `-j ACCEPT` → allow the traffic

> **Meaning:** Allow SSH (port 22) only from IP 172.16.238.187.

1.  **Block All Other Incoming Traffic:** Once the "good" traffic was allowed, I added a rule to drop everything else.
    ```bash
    # Block all incoming traffic (unless allowed by earlier rules).
    sudo iptables -A INPUT -j DROP
    ```
    *Note: Order matters! If the DROP rule was added first, the SSH connection would have been terminated immediately.*

<br>
<br>

#### 3. Securing Outgoing Traffic (OUTPUT Chain)
<a name="3-securing-outgoing-traffic-output-chain"></a>
Similarly, for outgoing traffic, I explicitly allowed connections to dependencies before blocking general access.

1.  **Allow Connection to Database:**
    ```bash
    # Allow your machine to connect to PostgreSQL on 172.16.238.11:5432.
    sudo iptables -A OUTPUT -p tcp -d 172.16.238.11 --dport 5432 -j ACCEPT
    ```

**Breakdown:**
- `-A OUTPUT` → add rule for outgoing traffic
- `-p tcp` → match TCP protocol
- `-d 172.16.238.11` → traffic going to this destination IP
- `--dport 5432` → target port 5432 (PostgreSQL)
- `-j ACCEPT` → allow this traffic

2.  **Allow Connection to Repo Server:**
    ```bash
    # Allow your machine to access 172.16.238.15 on port 80 (HTTP).
    sudo iptables -A OUTPUT -p tcp -d 172.16.238.15 --dport 80 -j ACCEPT
    ```
3.  **Block General Web Traffic:** I blocked all other HTTP and HTTPS traffic to prevent unauthorized external connections.
    ```bash
    # Block your machine from accessing any website on port 80 (HTTP).
    sudo iptables -A OUTPUT -p tcp --dport 80 -j DROP

    # Block your machine from accessing any website on port 443 (HTTPS).
    sudo iptables -A OUTPUT -p tcp --dport 443 -j DROP
    ```

<br>
<br>

#### 4. The Google HTTPS Challenge (DNS & Rule Insertion)
<a name="4-the-google-https-challenge-dns--rule-insertion"></a>
This was the trickiest part. I needed to allow HTTPS access to `google.com`.

* **The Problem:** I had already added a rule to `DROP` all HTTPS (port 443) traffic at the end of the OUTPUT chain.
* **The Requirement:** I needed to add an `ACCEPT` rule for Google *before* that DROP rule.
* **The DNS Issue:** `iptables` works with IP addresses. I tried to resolve `google.com` using `dig` or `nslookup`, but the commands were missing, and `apt install` failed because I had already blocked HTTP/HTTPS traffic!
* **The Solution:**
    1.  I used `iptables -I` (Insert) to place the new rule at the **top** of the chain (position 1), bypassing the existing DROP rules.
    2.  I allowed `iptables` to resolve the domain name directly in the rule (though for strict static IPs, resolving manually first is better practice).
    
    **The Final Command:**
    ```bash
    # Allow your system to access google.com on HTTPS (443), and put this rule at the top.
    sudo iptables -I OUTPUT 1 -p tcp -d google.com --dport 443 -j ACCEPT
    ```
    *`-I OUTPUT 1` inserts this rule as the very first rule in the OUTPUT chain.*

---

<br>
<br>

### Key Concepts & Lessons Learned
<a name="key-concepts--lessons-learned"></a>
* **Rule Order is Everything:** 
  * In iptables, rules are checked one by one from **top to bottom**.
  * The first matching rule wins — after that, iptables stops checking.
  * So if a DROP rule is above, your packet will get blocked before it reaches the ACCEPT rule.
  * That’s why you put specific ACCEPT rules first, and general DROP rules later.

* **`-A` vs `-I`:**
    * `-A` (Append): Adds a rule to the *end* of the list.
    * `-I` (Insert): Adds a rule to a specific position (default is 1, the top). This is essential for "hotfixing" a firewall without flushing all rules.

* **Stateful Inspection:** 
  * iptables is stateful, meaning it remembers the state of connections.
  So when your machine starts a connection (like opening a website), the return traffic must be allowed back in.
  * To allow this safely, we add: `-m state --state ESTABLISHED,RELATED -j ACCEPT`
  * Allow packets that are part of an already opened connection.
  * This prevents breaking normal traffic while still keeping the firewall secure.
  * In simple words:
    * If you start the conversation, this rule allows the reply to come back.


* **DNS Dependency:** 
  * If you block DNS (UDP port 53) or HTTP (port 80), your system won’t be able to resolve website names or reach many servers.
  * That means tools like `apt`, `curl`, `ping google.com`, `dig`, `wget` will stop working.
  * So basically —
    * If DNS is blocked, your system can’t find websites.
    * If HTTP is blocked, many downloads/installations will fail.
    * That’s why firewall rules must be added carefully.

---

### Command Reference
<a name="command-reference"></a>
| Flag | Meaning | Example |
| :--- | :--- | :--- |
| `-A` | **Append** to chain | `iptables -A INPUT ...` |
| `-I` | **Insert** at position | `iptables -I OUTPUT 1 ...` |
| `-p` | **Protocol** | `-p tcp` |
| `-s` | **Source** IP/subnet | `-s 192.168.1.5` |
| `-d` | **Destination** IP/subnet | `-d google.com` |
| `--dport` | **Destination Port** | `--dport 80` |
| `-j` | **Jump** to target | `-j ACCEPT`, `-j DROP` |
| `-L` | **List** rules | `iptables -L -n -v` |
   