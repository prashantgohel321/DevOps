# Linux Level 02 – Day 07: Install a Package

This document explains how to install the `git` package on multiple Linux servers using the `yum` package manager. The objective is to ensure that all application servers have Git installed to meet application deployment requirements.

---

<br>
<br>

- [Linux Level 02 – Day 07: Install a Package](#linux-level-02--day-07-install-a-package)
  - [Objective](#objective)
- [Understanding the Requirement](#understanding-the-requirement)
- [Step 1: Install on stapp01](#step-1-install-on-stapp01)
- [Step 2: Install on stapp02](#step-2-install-on-stapp02)
- [Step 3: Install on stapp03](#step-3-install-on-stapp03)
- [Deep Dive: How yum Works](#deep-dive-how-yum-works)
- [Command Breakdown](#command-breakdown)
- [Validation Across Servers](#validation-across-servers)
- [Key Outcome](#key-outcome)


<br>
<br>

## Objective

Install the `git` package on the following servers:

* `stapp01`
* `stapp02`
* `stapp03`

Package Manager: `yum` (used in CentOS/RHEL-based systems)

---

<br>
<br>

# Understanding the Requirement

Git is a distributed version control system used for tracking changes in source code. Many DevOps workflows depend on Git for pulling repositories, managing branches, and handling CI/CD pipelines.

Since these servers host applications, Git must be available system-wide.

Installing a package requires elevated privileges because it modifies protected system directories such as `/usr/bin`, `/etc`, and `/var/lib`.

---

<br>
<br>

# Step 1: Install on stapp01

Connect to the first server:

```bash
ssh tony@stapp01
# Password: Ir0nM@n
```

Install Git using sudo privileges:

```bash
sudo yum install git -y
# Password: Ir0nM@n (if prompted)
```

Verify installation:

```bash
git --version
```

Exit session:

```bash
exit
```

---

<br>
<br>

# Step 2: Install on stapp02

Connect to the second server:

```bash
ssh steve@stapp02
# Password: Am3ric@
```

Install Git:

```bash
sudo yum install git -y
```

Verify:

```bash
git --version
```

Exit session:

```bash
exit
```

---

<br>
<br>

# Step 3: Install on stapp03

Connect to the third server:

```bash
ssh banner@stapp03
# Password: BigGr33n
```

Install Git:

```bash
sudo yum install git -y
```

Verify:

```bash
git --version
```

Exit session:

```bash
exit
```

---

<br>
<br>

# Deep Dive: How yum Works

`yum` (Yellowdog Updater Modified) is a package management utility used in Red Hat-based Linux distributions.

When you run:

```bash
sudo yum install git -y
```

The system performs these steps:

1. Connects to configured repositories
2. Checks dependency requirements
3. Downloads required packages
4. Verifies package signatures (GPG check)
5. Installs files into system directories
6. Updates the RPM database

---

<br>
<br>

# Command Breakdown

* `sudo` → Executes command with root privileges
* `yum` → Package manager
* `install` → Action to install package
* `git` → Package name
* `-y` → Automatically answer "yes" to prompts

The `-y` flag is important for automation scripts because it prevents interactive confirmation prompts.

---

<br>
<br>

# Validation Across Servers

To confirm Git is installed successfully on each server:

```bash
git --version
```

Expected output format:

```text
git version X.Y.Z
```

---

<br>
<br>

# Key Outcome

The `git` package is installed and available on all three application servers (`stapp01`, `stapp02`, and `stapp03`). Each server is now prepared to handle version-controlled application workflows.
