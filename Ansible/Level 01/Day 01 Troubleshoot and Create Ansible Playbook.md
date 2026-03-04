# Ansible Level 01 – Day 01: Troubleshoot and Create Ansible Playbook

This document explains how to troubleshoot an incomplete Ansible inventory and create a simple playbook that performs a task on a remote host. The goal is to configure Ansible so that it can connect to App Server 3 and create a file automatically without interactive prompts.

---

## Objective

Configure Ansible to perform the following:

* **Target Host:** `stapp03`
* **Inventory File:** `/home/thor/ansible/inventory`
* **Playbook File:** `/home/thor/ansible/playbook.yml`
* **Task:** Create an empty file `/tmp/file.txt` on the remote host
* **Execution Command:**

```
ansible-playbook -i inventory playbook.yml
```

The command must execute successfully without password prompts.

---

# Understanding the Problem

Ansible requires two key components to run automation:

1. **Inventory** – defines which hosts Ansible should manage and how to connect to them.
2. **Playbook** – defines the tasks that should be executed on those hosts.

If the inventory is incomplete or missing connection details, Ansible cannot connect to the target system.

In this scenario, the inventory must explicitly define the connection parameters so that the playbook can run without requiring interactive SSH authentication.

---

# Step 1: Update the Inventory File

Navigate to the Ansible working directory:

```bash
cd /home/thor/ansible
```

Edit the inventory file:

```bash
vi inventory
```

Add the following configuration:

```ini
stapp03 ansible_host=stapp03 ansible_user=banner ansible_ssh_pass=BigGr33n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Explanation of Fields

* `stapp03` → Logical hostname used by Ansible
* `ansible_host` → Actual SSH target
* `ansible_user` → Remote login user
* `ansible_ssh_pass` → Password used for SSH authentication
* `ansible_ssh_common_args` → Disables the SSH host key verification prompt

Without the last parameter, Ansible may pause waiting for manual confirmation of the SSH fingerprint.

---

# Step 2: Create the Playbook

Create the playbook file:

```bash
vi playbook.yml
```

Insert the following configuration:

```yaml
---
- name: Configure App Server 3
  hosts: stapp03

  tasks:

    - name: Create an empty file at /tmp/file.txt
      file:
        path: /tmp/file.txt
        state: touch
```

---

# Explanation of Playbook Structure

### Play Definition

```yaml
- name: Configure App Server 3
  hosts: stapp03
```

This defines the play and specifies that tasks should run on the host `stapp03` defined in the inventory.

---

### Task Section

```yaml
file:
  path: /tmp/file.txt
  state: touch
```

The `file` module manages files on remote hosts.

The `state: touch` parameter behaves similarly to the Linux `touch` command:

* Creates the file if it does not exist
* Updates the timestamp if the file already exists

This keeps the task idempotent, meaning it can run multiple times without causing unintended changes.

---

# Step 3: Execute the Playbook

Run the playbook using the required command:

```bash
ansible-playbook -i inventory playbook.yml
```

---

# Expected Execution Output

Example output:

```
PLAY [Configure App Server 3]

TASK [Gathering Facts]
ok: [stapp03]

TASK [Create an empty file at /tmp/file.txt]
changed: [stapp03]

PLAY RECAP
stapp03 : ok=2 changed=1 unreachable=0 failed=0
```

---

# Internal Workflow of the Execution

When the command runs, Ansible performs these steps:

1. Reads the inventory file
2. Establishes SSH connection to the remote host
3. Gathers system facts
4. Executes the task defined in the playbook
5. Reports the execution result

Because authentication parameters were embedded in the inventory, the process runs non-interactively.

---

# Key Outcome

The Ansible configuration now successfully connects to `stapp03` and executes the playbook. The automation creates the file `/tmp/file.txt` on the remote server without requiring manual authentication or additional command-line parameters.
