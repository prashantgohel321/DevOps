# Ansible Level 03 Day 03: Ansible Manage Services

This document outlines the solution for Ansible Level 03 Day 03. The objective was to create an Ansible playbook that installs the `vsftpd` (Very Secure FTP Daemon) package on all application servers and ensures the service is started and enabled to run automatically on boot.

## Table of Contents
- [Ansible Level 03 Day 03: Ansible Manage Services](#ansible-level-03-day-03-ansible-manage-services)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify the Environment](#1-verify-the-environment)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Package Management (`yum`)](#package-management-yum)
    - [Service Management (`service`)](#service-management-service)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install and configure the `vsftpd` service across all application servers.

**Requirements:**
1.  **Playbook Location:** `/home/thor/ansible/playbook.yml` on the jump host.
2.  **Target Hosts:** All application servers.
3.  **Inventory Location:** `/home/thor/ansible/inventory` (Already exists).
4.  **Tasks:**
    * Install the `vsftpd` package.
    * Start the `vsftpd` service.
    * Enable the `vsftpd` service (to start on system boot).
5.  **Constraint:** The user `thor` must be able to run it securely using `ansible-playbook -i inventory playbook.yml` without any additional arguments.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Before creating the playbook, it's good practice to verify the pre-existing inventory file to ensure the target hosts and their connection variables are properly set up for passwordless/argumentless execution.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```
*(Verify that it contains the app servers with their respective `ansible_user` and password/SSH key settings).*

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create a YAML playbook to handle the package installation and service management. Both actions modify system-level configurations, so they require root privileges (`become: yes`).

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Install and configure vsftpd on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Install vsftpd package
      yum:
        name: vsftpd
        state: present

    - name: Start and enable vsftpd service
      service:
        name: vsftpd
        state: started
        enabled: yes
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook from the `/home/thor/ansible/` directory.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Expected Output:**
```text
PLAY [Install and configure vsftpd on all app servers] ******************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Install vsftpd package] *******************************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

TASK [Start and enable vsftpd service] **********************************************
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP **************************************************************************
stapp01                    : ok=3    changed=2    unreachable=0    failed=0    ...
stapp02                    : ok=3    changed=2    unreachable=0    failed=0    ...
stapp03                    : ok=3    changed=2    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
To independently verify that the service is running across all nodes, use an ad-hoc command:
```bash
ansible all -i inventory -m command -a "systemctl status vsftpd" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Package Management (`yum`)
<a name="package-management-yum"></a>
The `yum` module is used to manage packages on RedHat-based distributions (like CentOS, which is commonly used in Stratos DC).
* **`name: vsftpd`**: Specifies the package we want to manage.
* **`state: present`**: Instructs Ansible to ensure the package is installed. If it is already installed, Ansible reports `ok` and does nothing (maintaining idempotency).

### Service Management (`service`)
<a name="service-management-service"></a>
The `service` module is used to control system services (supporting both `systemd` and `init` systems).
* **`state: started`**: Ensures the service is currently running. If it's stopped, Ansible will start it.
* **`enabled: yes`**: Equivalent to running `systemctl enable vsftpd`. This creates the necessary system symlinks so the service automatically starts up if the server reboots.

**Why Order Matters:**
The order of tasks in the playbook is crucial. You cannot start or enable the `vsftpd` service before the `vsftpd` package is installed. The playbook processes tasks sequentially from top to bottom.
  
