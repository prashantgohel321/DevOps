# DevOps Day 82: Ansible Playbooks & Inventories - Testing on App Server 1

This document provides a comprehensive guide to completing the Ansible task for DevOps Day 82. It covers the creation of an inventory file and the execution of a playbook to test connectivity with an application server.

## Table of Contents
- [DevOps Day 82: Ansible Playbooks \& Inventories - Testing on App Server 1](#devops-day-82-ansible-playbooks--inventories---testing-on-app-server-1)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Understanding Ansible Concepts](#understanding-ansible-concepts)
    - [What is Ansible?](#what-is-ansible)
    - [Inventory Files](#inventory-files)
    - [Playbooks](#playbooks)
    - [Modules](#modules)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Navigate to the Directory](#1-navigate-to-the-directory)
    - [Here is the playbook file provided by kodekloud:](#here-is-the-playbook-file-provided-by-kodekloud)
    - [Playbooks](#playbooks-1)
    - [2. Create the Inventory File](#2-create-the-inventory-file)
    - [3. Validate Connectivity (Ad-hoc Command)](#3-validate-connectivity-ad-hoc-command)
    - [4. Run the Playbook](#4-run-the-playbook)
  - [Command Breakdown](#command-breakdown)
  - [Troubleshooting \& Common Scenarios](#troubleshooting--common-scenarios)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** The Nautilus DevOps team needs to test Ansible playbooks on `App Server 1` in the Stratos Datacenter. The playbooks are already located at `/home/thor/playbook/` on the jump host.

**Requirements:**
1.  **Inventory File:** Create an INI-style inventory file named `inventory` inside `/home/thor/playbook/`.
2.  **Target Host:** Add App Server 1 (hostname `stapp01`) to this inventory.
3.  **Variables:** Include necessary connection variables (`ansible_user`, `ansible_ssh_pass`).
4.  **Validation:** Execute the existing `playbook.yml` using the newly created inventory.

---

## Understanding Ansible Concepts
<a name="understanding-ansible-concepts"></a>

### What is Ansible?
<a name="what-is-ansible"></a>
Ansible is an open-source automation tool used for configuration management, application deployment, and task automation. It is **agentless**, meaning it doesn't require any software to be installed on the target nodes. It connects via SSH (for Linux) or WinRM (for Windows).

### Inventory Files
<a name="inventory-files"></a>
An **Inventory** is a file (often `hosts` or `inventory`) that lists the servers (hosts) Ansible will manage. It can be formatted as INI or YAML.

**INI Format Example:**
```ini
[webservers]
server1 ansible_host=192.168.1.10
server2 ansible_host=192.168.1.11

[dbservers]
db1 ansible_host=192.168.1.20
```

### Playbooks
<a name="playbooks"></a>
A **Playbook** is a YAML file containing a list of **plays**. Each play maps a group of hosts to a list of **tasks**. Each task calls an Ansible **module**. Playbooks describe the *desired state* of your system (e.g., "Ensure Apache is installed").

**Example Playbook (`playbook.yml`):**
```yaml
---
- name: Test Connection
  hosts: all
  tasks:
    - name: Ping the server
      ping:
```

### Modules
<a name="modules"></a>
Modules are the units of work in Ansible. They are standalone scripts that Ansible executes on your behalf.
* **`ping`**: Tries to connect to the host and verify a usable python environment.
* **`command` / `shell`**: Executes shell commands.
* **`yum` / `apt`**: Manages packages.
* **`service`**: Manages services (start, stop, restart).
* **`copy`**: Copies files from the control node to managed nodes.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Navigate to the Directory
<a name="1-navigate-to-the-directory"></a>
The task specifies that playbooks are in `/home/thor/playbook/`. Move there first.

```bash
cd /home/thor/playbook/
```

### Here is the playbook file provided by kodekloud:
### Playbooks

<a name="playbooks"></a>

**Provided Playbook (`playbook.yml`) – with line-by-line explanation:**

```yaml
---                                    # Start of YAML document.
- hosts: all                           # Targets all hosts from the inventory (here, `stapp01`).
  become: yes                          # Enables sudo privilege escalation.
  become_user: root                    # Runs tasks as the root user.
  tasks:                               # Defines the list of actions to execute.
    - name: Install httpd package      
      yum:                             # Uses the YUM package manager module.
        name: httpd                    # Specifies the Apache package.
        state: installed               # Ensures Apache is installed.
    
    - name: Start service httpd
      service:                         # Controls system services.
        name: httpd                    # Starts the Apache service.
```


### 2. Create the Inventory File
<a name="2-create-the-inventory-file"></a>
We need to create a file named `inventory`. It must contain the server name (`stapp01`) and the connection credentials.

**Command:**
```bash
vi inventory
```

**Content to Add (INI Format):**
```ini
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n


# OR


[app]                        # Group name
stapp01                      # Target application server's hostname

[app:vars]                   # Group variables
ansible_user=tony            # SSH username for App Server 1
ansible_ssh_pass=Ir0nM@n     # SSH password for user `tony`
```

* **`stapp01`**: The alias/hostname used in Ansible commands.
* **`ansible_host=stapp01`**: The actual DNS name or IP address Ansible connects to.
* **`ansible_user=tony`**: The SSH username for App Server 1.
* **`ansible_ssh_pass=Ir0nM@n`**: The SSH password for user `tony`.

*Alternative grouping structure:*
```ini
[app_servers]
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n
```

### 3. Validate Connectivity (Ad-hoc Command)
<a name="3-validate-connectivity-ad-hoc-command"></a>
Before running the full playbook, it is best practice to test if Ansible can actually talk to the server using the `ping` module.

**Command:**
```bash
ansible all -i inventory -m ping
```

* **`all`**: Target all hosts listed in the inventory.
* **`-i inventory`**: Use the specific inventory file we just created.
* **`-m ping`**: Run the `ping` module.

**Expected Output:**
```json
stapp01 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```

### 4. Run the Playbook
<a name="4-run-the-playbook"></a>
Finally, execute the provided playbook as requested.

**Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Breakdown:**
* **`PLAY [ ... ]`**: The start of the play.
* **`TASK [Gathering Facts]`**: Ansible automatically collects info about the remote system (OS, IP, etc.).
* **`TASK [ ... ]`**: The custom tasks defined in `playbook.yml`.
* **`PLAY RECAP`**: A summary. `ok=X` means success. `failed=0` is critical.

---

## Command Breakdown
<a name="command-breakdown"></a>

| Command Segment | Explanation |
| :--- | :--- |
| **`ansible`** | The CLI tool for running ad-hoc commands (one-off tasks). |
| **`ansible-playbook`** | The CLI tool for running Ansible playbooks (orchestrated workflows). |
| **`-i inventory`** | **Inventory Flag:** Tells Ansible exactly which file to look at for the list of servers. Without this, it defaults to `/etc/ansible/hosts`. |
| **`-m ping`** | **Module Flag:** Tells Ansible which module to run. |
| **`all`** | **Host Pattern:** Refers to every host listed in the inventory file. You could also use `stapp01` or a group name like `[web]`. |
| **`playbook.yml`** | The YAML file containing the definition of tasks to execute. |

---

## Troubleshooting & Common Scenarios
<a name="troubleshooting--common-scenarios"></a>

**Scenario 1: `Permission denied (publickey,password)`**
* **Cause:** Wrong username or password in the inventory file.
* **Fix:** Double-check `ansible_user` (is it `tony`?) and `ansible_ssh_pass` (is it `Ir0nM@n`?). Ensure there are no extra spaces.

**Scenario 2: `UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh..."}`**
* **Cause:** The server `stapp01` might be down, or DNS resolution is failing.
* **Fix:** Try `ping stapp01` from the command line. If that fails, check the server status or IP address.

**Scenario 3: `SSH authenticity of host 'stapp01' can't be established.`**
* **Cause:** This is the first time the jump host is connecting to `stapp01`.
* **Fix:** Ansible usually hangs here waiting for "yes". You can:
    1.  Run `ssh tony@stapp01` manually once and type "yes".
    2.  Add `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` to your inventory line to bypass this check automatically.

**Scenario 4: `syntax error` in inventory**
* **Cause:** INI files are sensitive to structure.
* **Fix:** Ensure variables are on the same line as the hostname, separated by spaces: `host var1=value var2=value`.
   