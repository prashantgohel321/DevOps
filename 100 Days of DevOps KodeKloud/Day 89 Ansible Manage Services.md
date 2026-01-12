# DevOps Day 89: Ansible Manage Services

This document outlines the solution for DevOps Day 89. The objective was to create an Ansible playbook that installs and configures the `httpd` (Apache) web server on multiple application servers, ensuring the service is both running and enabled to start on boot.

## Table of Contents
- [DevOps Day 89: Ansible Manage Services](#devops-day-89-ansible-manage-services)
  - [Table of Contents](#table-of-contents)
  - [Task Overview](#task-overview)
  - [Step-by-Step Solution](#step-by-step-solution)
    - [1. Verify Inventory](#1-verify-inventory)
    - [2. Create the Playbook](#2-create-the-playbook)
    - [3. Execute and Validate](#3-execute-and-validate)
  - [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    - [Package Management (`yum`)](#package-management-yum)
    - [Service Management (`service`)](#service-management-service)
    - [Idempotency](#idempotency)
  - [Troubleshooting](#troubleshooting)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Install `httpd` on all app servers in Stratos DC and ensure the service is active and enabled.

**Requirements:**
1.  **Playbook:** Create `/home/thor/ansible/playbook.yml`.
2.  **Package:** Install the `httpd` package.
3.  **Service:** Start the `httpd` service and enable it (autostart on boot).
4.  **Targets:** All app servers defined in the existing inventory.
5.  **User:** The task must be performed by user `thor` from the jump host.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify Inventory
<a name="1-verify-inventory"></a>
First, I verified the existing inventory file to ensure connection details for `stapp01`, `stapp02`, and `stapp03` were correct.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

**Content:**
```ini
stapp01 ansible_host=172.16.238.10 ansible_ssh_pass=Ir0nM@n ansible_user=tony
stapp02 ansible_host=172.16.238.11 ansible_ssh_pass=Am3ric@ ansible_user=steve
stapp03 ansible_host=172.16.238.12 ansible_ssh_pass=BigGr33n ansible_user=banner
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
I created a YAML playbook to define the desired state configuration.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Install and Configure httpd
  hosts: all
  become: true  # Required for installing packages and managing system services
  tasks:
    - name: Install httpd package
      yum:
        name: httpd
        state: present

    - name: Start and Enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
I executed the playbook and validated the results.

**Execution Command:**
```bash
ansible-playbook -i inventory playbook.yml
```

**Output Analysis:**
```text
PLAY [Install and Configure httpd] **************************************************

TASK [Install httpd package] ********************************************************
changed: [stapp02]
changed: [stapp01]
changed: [stapp03]

TASK [Start and Enable httpd service] ***********************************************
changed: [stapp03]
changed: [stapp02]
changed: [stapp01]
```
* **Changed:** Indicates that Ansible successfully installed the missing package and changed the service state from stopped to started.

**Verification Command:**
I verified the service status on all nodes using an ad-hoc command.
```bash
ansible all -i inventory -a "systemctl status httpd"
```
*Result:* All servers returned `Active: active (running)`, confirming success.

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Package Management (`yum`)
<a name="package-management-yum"></a>
The `yum` module allows us to manage packages on RedHat-based systems (like CentOS/RHEL).
* `name: httpd`: Specifies the package to install.
* `state: present`: Ensures the package is installed. If it's already there, Ansible does nothing.

### Service Management (`service`)
<a name="service-management-service"></a>
The `service` module controls system services (systemd, init.d).
* `state: started`: Ensures the service is currently running. If it crashed or was stopped, Ansible starts it.
* `enabled: yes`: Creates the necessary symlinks so the service starts automatically when the server reboots.

### Idempotency
<a name="idempotency"></a>
A key feature of Ansible. As mentioned in the solution notes:
> "If any error occurs... I can run plays on all servers again, because of its idempotent behaviour it wont change the things if things were changed previously."

This means you can safely run this playbook 100 times. The first time, it installs Apache. The next 99 times, it checks the state, sees Apache is already installed and running, and reports `ok` (no changes), ensuring stability without side effects.

---

## Troubleshooting
<a name="troubleshooting"></a>

**Issue: Service fails to start**
* **Cause:** Port 80 might be in use, or configuration files are invalid.
* **Fix:** Check `systemctl status httpd -l` or `/var/log/messages` on the remote host.

**Issue: "Permission Denied"**
* **Cause:** Managing services and installing packages requires root privileges.
* **Fix:** Ensure `become: true` is set in the playbook.
  