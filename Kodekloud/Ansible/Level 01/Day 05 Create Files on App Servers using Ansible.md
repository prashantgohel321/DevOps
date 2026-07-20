# Ansible Level 01 – Day 05: Create Files on App Servers using Ansible

This document explains how to automate the creation of a file across multiple application servers while assigning different ownership based on the host. The automation relies on Ansible inventory variables so that a single playbook can dynamically apply the correct configuration to each system.

---

## Objective

Create a file on all application servers with the following properties:

* **File Path:** `/tmp/webdata.txt`
* **Permissions:** `0744`
* **Owner Requirements:**

  * `stapp01` → `tony`
  * `stapp02` → `steve`
  * `stapp03` → `banner`

File locations:

* **Inventory:** `~/playbook/inventory`
* **Playbook:** `~/playbook/playbook.yml`

Execution command:

```
ansible-playbook -i inventory playbook.yml
```

The command must run successfully without requiring additional authentication flags.

---

# Automation Design

The automation is implemented using two components:

1. **Inventory** – defines the servers and their connection parameters
2. **Playbook** – defines the file creation task

The inventory stores the login user for each server. The playbook then references that variable to dynamically set the correct ownership.

---

# Step 1: Create the Inventory File

Create the working directory and inventory file.

```bash
mkdir -p ~/playbook
cd ~/playbook
vi inventory
```

Insert the following configuration:

```ini
[app]
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n
stapp02 ansible_host=stapp02 ansible_user=steve ansible_ssh_pass=Am3ric@
stapp03 ansible_host=stapp03 ansible_user=banner ansible_ssh_pass=BigGr33n

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

# Explanation of Inventory Structure

`[app]`

Defines a host group containing all application servers.

Each host entry contains connection parameters required for SSH authentication.

`ansible_host`

The hostname or IP used for SSH connectivity.

`ansible_user`

Defines the remote login account for that server.

`ansible_ssh_pass`

Password used for SSH authentication.

`[all:vars]`

Defines variables applied to every host in the inventory.

`ansible_ssh_common_args='-o StrictHostKeyChecking=no'`

Prevents SSH from asking for manual host fingerprint confirmation.

---

# Step 2: Create the Playbook

Create the playbook file.

```bash
vi playbook.yml
```

Insert the following configuration.

```yaml
---
- name: Create files on application servers
  hosts: all
  become: yes

  tasks:

    - name: Create /tmp/webdata.txt with required permissions
      file:
        path: /tmp/webdata.txt
        state: touch
        mode: '0744'
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
```

---

# Explanation of the Playbook

### Target Hosts

```
hosts: all
```

The task runs on every host defined in the inventory.

---

### Privilege Escalation

```
become: yes
```

Changing file ownership requires root privileges. This directive allows Ansible to execute the task using sudo.

---

### File Module

The `file` module manages file attributes such as creation, permissions, and ownership.

```
state: touch
```

Creates the file if it does not exist.

```
mode: '0744'
```

Defines file permissions:

* Owner → read, write, execute
* Group → read only
* Others → read only

---

# Dynamic Ownership Assignment

```
owner: "{{ ansible_user }}"
```

The variable `ansible_user` comes from the inventory.

During execution Ansible replaces the variable with the appropriate value for each host.

Example substitutions:

* `stapp01` → owner becomes `tony`
* `stapp02` → owner becomes `steve`
* `stapp03` → owner becomes `banner`

This technique avoids writing multiple host-specific tasks.

---

# Step 3: Execute the Playbook

Run the playbook using the required command.

```bash
ansible-playbook -i inventory playbook.yml
```

---

# Expected Execution Output

Example execution result:

```
PLAY [Create files on application servers]

TASK [Gathering Facts]
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Create /tmp/webdata.txt with required permissions]
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP
stapp01 : ok=2 changed=1 unreachable=0 failed=0
stapp02 : ok=2 changed=1 unreachable=0 failed=0
stapp03 : ok=2 changed=1 unreachable=0 failed=0
```

---

# Optional Verification

Verify the file and its ownership on all servers using an ad‑hoc command.

```bash
ansible all -i inventory -m command -a "ls -l /tmp/webdata.txt"
```

Expected output will show the correct owner for each host.

---

# Internal Execution Flow

When the playbook runs, Ansible performs the following operations:

1. Reads the inventory
2. Connects to each server using SSH
3. Escalates privileges using sudo
4. Creates the file `/tmp/webdata.txt`
5. Applies the specified permissions and ownership

The dynamic variable ensures the correct owner is applied automatically for each server.

---

# Key Outcome

A single Ansible playbook successfully creates `/tmp/webdata.txt` on all application servers while assigning the correct owner and permissions based on the host executing the task.
