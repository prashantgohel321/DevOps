# Ansible Level 01 – Day 02: Create Ansible Inventory for App Server Testing

This document explains how to create an Ansible inventory file from scratch using the INI format. The inventory defines the remote systems Ansible can manage and specifies the connection details required to access them.

---

## Objective

Create an inventory file that allows Ansible to connect to **App Server 2**.

Configuration requirements:

* **Target Host:** `stapp02`
* **Inventory Location:** `/home/thor/playbook/inventory`
* **Inventory Format:** INI
* **Execution Requirement:** The command `ansible-playbook -i inventory playbook.yml` must work without prompting for SSH credentials.

---

# Understanding the Role of Inventory in Ansible

Ansible uses an inventory file to know:

* Which hosts it should manage
* How to connect to those hosts
* What variables are associated with each host

Without an inventory, Ansible has no information about the infrastructure it should automate.

The inventory can include hostnames, IP addresses, connection variables, authentication credentials, and grouping definitions.

---

# Step 1: Create the Directory and Inventory File

Create the working directory and the inventory file.

```bash
mkdir -p /home/thor/playbook
cd /home/thor/playbook
vi inventory
```

---

# Step 2: Define the Inventory Entry

Insert the following line in the file:

```ini
stapp02 ansible_host=stapp02 ansible_user=steve ansible_ssh_pass=Am3ric@ ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

# Explanation of Inventory Fields

`stapp02`

This is the alias used by Ansible to refer to the host in playbooks.

---

`ansible_host=stapp02`

Defines the actual hostname or IP address used for the SSH connection.

---

`ansible_user=steve`

Specifies the remote user account used to log into the system.

---

`ansible_ssh_pass=Am3ric@`

Defines the password required for SSH authentication.

---

`ansible_ssh_common_args='-o StrictHostKeyChecking=no'`

Disables SSH host key verification so that Ansible does not pause waiting for manual confirmation during the first connection.

---

# Step 3: Validate the Inventory

Before running any playbook, verify connectivity using the Ansible ping module.

```bash
ansible all -i inventory -m ping
```

---

# Expected Output

Successful connectivity produces output similar to:

```json
stapp02 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Receiving `pong` confirms that:

* The inventory is valid
* SSH authentication works
* Ansible can communicate with the remote host

---

# How Ansible Uses This Inventory

When running the command:

```bash
ansible-playbook -i inventory playbook.yml
```

Ansible performs the following steps:

1. Reads the inventory file
2. Resolves host connection parameters
3. Establishes SSH connectivity
4. Executes the playbook tasks on the remote system

Because credentials are embedded inside the inventory, the playbook runs without requiring interactive input.

---

# INI Inventory Format vs YAML Inventory

Ansible supports multiple inventory formats.

**INI Inventory**

* Simpler syntax
* Flat structure
* Suitable for small environments

Example:

```
stapp02 ansible_host=stapp02
```

**YAML Inventory**

* Structured hierarchy
* Better for large infrastructures
* Supports complex grouping

Example:

```yaml
all:
  hosts:
    stapp02:
      ansible_host: stapp02
      ansible_user: steve
```

---

# Security Considerations

Storing plaintext passwords in inventory files is acceptable for lab environments but not recommended for production systems.

In real deployments, secure alternatives include:

* SSH key authentication
* Ansible Vault
* External secrets managers

These approaches prevent exposure of sensitive credentials.

---

# Key Outcome

The inventory file is successfully created at `/home/thor/playbook/inventory`. Ansible can now connect to `stapp02` automatically and execute playbooks without requiring manual SSH authentication.
