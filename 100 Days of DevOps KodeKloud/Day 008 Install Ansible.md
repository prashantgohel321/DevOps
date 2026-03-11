# DevOps Day 08 — Installing and Preparing an Ansible Controller 

<br>
<br>

## Real Scenario

In modern infrastructure environments, managing servers manually quickly becomes inefficient. When a system administrator needs to configure dozens or hundreds of servers, logging into each one individually and running commands is slow, error‑prone, and difficult to maintain.

Configuration management tools solve this problem by allowing administrators to define infrastructure tasks once and execute them across many machines automatically.

**Ansible** is one of the most widely used tools for this purpose. It allows administrators to automate tasks such as:

* application deployment
* server configuration
* infrastructure provisioning
* patch management
* system audits

Unlike some configuration management tools, Ansible follows an **agentless architecture**, meaning that the target servers do not require any special software installed. Ansible connects to servers using **SSH**, executes tasks remotely, and returns the results.

In this task, the goal was to convert the `jump_host` machine into an **Ansible controller**, which is the central system responsible for running automation tasks.

Reference source: fileciteturn12file0

---

<br>
<br>

# Understanding the Ansible Architecture

Ansible environments typically contain two main components.

## Controller Node

The controller node is the machine where Ansible is installed and executed.

This system contains:

* playbooks (automation instructions written in YAML)
* inventory files (lists of servers)
* configuration files
* automation scripts

When a command such as `ansible-playbook` runs, it is executed from the controller.

In this task:

```bash
jump_host → Ansible Controller
```

---

<br>
<br>

## Managed Nodes

Managed nodes are the servers that Ansible controls.

These systems do **not require an agent**. Instead, Ansible connects using SSH and runs modules remotely.

Example managed nodes in this environment:

```bash
stapp01
stapp02
stapp03
```

---

<br>
<br>

# Step 1 — Installing Ansible

The installation was performed using Python's package manager.

```bash
sudo pip3 install ansible==4.7.0
```

Understanding the command helps explain how Ansible is installed.

---

## sudo

The command begins with `sudo` so the installation occurs **system‑wide**.

Without `sudo`, Python packages are installed only for the current user inside:

```bash
~/.local/bin
```

Installing with `sudo` places the executable in:

```bash
/usr/local/bin
```

This ensures the `ansible` command is available globally to all users.

---

## pip3

`pip3` is the package manager used for installing Python packages.

Ansible itself is written in Python, so it can be installed directly through pip.

Using pip also allows administrators to **pin a specific version** of the software.

---

## Version Pinning

The installation specifies a version number.

```bash
ansible==4.7.0
```

The `==` operator ensures exactly version **4.7.0** is installed.

This practice is important in DevOps environments because automation scripts may depend on specific versions of tools.

Installing the latest version without testing may break automation pipelines.

---

<br>
<br>

# Step 2 — Verifying the Installation

After installation, several checks were performed.

### Check Ansible Version

```bash
ansible --version
```

This command displays:

* Ansible core version
* Python interpreter version
* configuration file path
* executable location

Example output:

```bash
ansible [core 2.11.12]
  executable location = /usr/local/bin/ansible
```

---

### Locate the Executable

```bash
which ansible
```

This command searches the system PATH and shows where the executable is located.

Expected output:

```bash
/usr/local/bin/ansible
```

This confirms that the installation is global.

---

### Verify the Python Package

```bash
pip3 show ansible
```

This command displays detailed information about the installed Python package.

**Example output:**

```bash
Name: ansible
Version: 4.7.0
Location: /usr/local/lib/python3.8/site-packages
```

---

<br>
<br>

# Understanding the Ansible vs Ansible-Core Difference

One confusing detail during verification is the difference between **ansible** and **ansible-core**.

**When running:**

```bash
ansible --version
```

**The output may display something like:**

```bash
ansible [core 2.11.12]
```

This does not mean the installation failed.

---

<br>
<br>

## ansible (Community Package)

The package `ansible` version **4.7.0** is a large bundle containing:

* hundreds of modules
* plugins
* integrations
* documentation

This is the full Ansible distribution used by most users.

---

## ansible-core (Execution Engine)

`ansible-core` is the lightweight engine responsible for executing playbooks.

It provides:

* SSH connectivity
* task execution
* module framework
* inventory processing

The community package includes a specific version of ansible-core.

For example:

```bash
Ansible 4.7.0 → includes ansible-core 2.11.12
```

Therefore seeing `core 2.11.12` in the output is expected.

---

<br>
<br>

# Why DevOps Engineers Use Ansible

Ansible offers several advantages that make it popular in infrastructure automation.

## Agentless Architecture

Managed nodes do not require additional software installation.

Ansible simply connects using SSH.

---

## Simple Configuration Language

Automation tasks are written in **YAML**, which is human‑readable and easy to maintain.

Example playbook snippet:

```bash
- hosts: webservers
  tasks:
    - name: Install nginx
      package:
        name: nginx
        state: present
```

---

## Idempotent Operations

Most Ansible modules are **idempotent**, meaning they only make changes when necessary.

Running the same playbook multiple times produces the same result without causing duplicate changes.

---

<br>
<br>

# Common Problems During Installation

## Forgetting sudo

Running pip without sudo installs packages only for the current user.

The command may not be accessible globally.

---

## Version Confusion

Users may think the installation failed because the output shows the `ansible-core` version instead of the community package version.

---

## PATH Issues

If `/usr/local/bin` is not included in the system PATH, the ansible command may not be found.

---

<br>
<br>

# Useful Ansible Commands

**Check Ansible installation:**

```bash
ansible --version
```

**Run a simple connectivity test:**

```bash
ansible all -m ping
```

**View configuration file:**

```bash
ansible-config view
```

**List installed collections:**

```bash
ansible-galaxy collection list
```

---

<br>
<br>

# Practical Outcome

After completing the setup:

* The `jump_host` acts as the **Ansible controller**
* Ansible version **4.7.0** is installed system‑wide
* The `ansible` command is globally available
* The system is ready to manage remote servers using automation

Setting up the controller node is the first step toward building automated infrastructure workflows using Ansible.
