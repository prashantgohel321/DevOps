# Ansible Level 01 – Day 04: Copy Data to App Servers using Ansible

This document explains how to automate file distribution from the Ansible control node to multiple application servers. The automation uses an Ansible inventory and playbook so that a file located on the control node is copied to all remote servers consistently.

---

## Objective

Copy a file from the control node to all application servers.

Configuration requirements:

* **Source File:** `/usr/src/data/index.html`
* **Destination Directory:** `/opt/data/`
* **Inventory Location:** `/home/thor/ansible/inventory`
* **Playbook Location:** `/home/thor/ansible/playbook.yml`

The playbook must run successfully using the command:

```
ansible-playbook -i inventory playbook.yml
```

No additional command‑line authentication parameters should be required.

---

# Understanding the Automation Flow

Ansible automation typically follows three main components:

1. **Control Node** – the system where Ansible is installed and from where commands are executed.
2. **Inventory** – defines the list of managed hosts and connection details.
3. **Playbook** – defines the tasks that should be executed on those hosts.

In this scenario, the control node distributes a web file to all application servers using the Ansible `copy` module.

---

# Step 1: Create the Inventory File

Create the directory and inventory file.

```bash
mkdir -p /home/thor/ansible
cd /home/thor/ansible
vi inventory
```

Insert the following configuration:

```ini
stapp01 ansible_host=stapp01 ansible_user=tony ansible_ssh_pass=Ir0nM@n
stapp02 ansible_host=stapp02 ansible_user=steve ansible_ssh_pass=Am3ric@
stapp03 ansible_host=stapp03 ansible_user=banner ansible_ssh_pass=BigGr33n

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

# Explanation of Inventory Configuration

Each line defines a managed node and the connection parameters required for SSH authentication.

`stapp01`, `stapp02`, `stapp03`

Logical hostnames used by Ansible when executing tasks.

`ansible_host`

Specifies the actual hostname or address used for the SSH connection.

`ansible_user`

Defines the remote login user.

`ansible_ssh_pass`

Defines the password used for authentication.

`[all:vars]`

Defines variables that apply to every host in the inventory.

`ansible_ssh_common_args='-o StrictHostKeyChecking=no'`

Disables SSH host key verification prompts during the first connection.

---

# Step 2: Create the Playbook

Create the playbook file.

```bash
vi playbook.yml
```

Insert the following playbook configuration.

```yaml
---
- name: Copy data to all application servers
  hosts: all
  become: yes

  tasks:

    - name: Copy index.html to application servers
      copy:
        src: /usr/src/data/index.html
        dest: /opt/data/
```

---

# Explanation of Playbook Structure

### Play Definition

```yaml
hosts: all
```

This tells Ansible to execute the tasks on every host defined in the inventory.

---

### Privilege Escalation

```yaml
become: yes
```

The destination directory `/opt/data` typically requires root privileges. This parameter instructs Ansible to execute the task using elevated privileges (sudo).

---

### Copy Module

```yaml
copy:
  src: /usr/src/data/index.html
  dest: /opt/data/
```

The `copy` module transfers files from the control node to remote hosts.

`src`

Path to the file on the control node.

`dest`

Destination path on the remote system. When the path ends with `/`, the file is placed inside that directory.

---

# Step 3: Execute the Playbook

Run the playbook using the required command.

```bash
ansible-playbook -i inventory playbook.yml
```

---

# Expected Execution Output

Successful execution produces output similar to the following.

```
PLAY [Copy data to all application servers]

TASK [Gathering Facts]
ok: [stapp01]
ok: [stapp02]
ok: [stapp03]

TASK [Copy index.html to application servers]
changed: [stapp01]
changed: [stapp02]
changed: [stapp03]

PLAY RECAP
stapp01 : ok=2 changed=1 unreachable=0 failed=0
stapp02 : ok=2 changed=1 unreachable=0 failed=0
stapp03 : ok=2 changed=1 unreachable=0 failed=0
```

---

# Internal Execution Flow

When the playbook runs, Ansible performs the following sequence:

1. Reads the inventory file
2. Establishes SSH connections to each host
3. Gathers system facts
4. Transfers the file from the control node
5. Writes the file to the target directory on each server

Because all credentials are defined inside the inventory, the automation runs without requiring interactive authentication.

---

# Key Outcome

The file `/usr/src/data/index.html` is successfully distributed from the Ansible control node to `/opt/data/` on all application servers. The process is fully automated and repeatable through the Ansible playbook.
