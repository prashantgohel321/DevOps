# Ansible Level 01 – Day 03: Configure Default SSH User for Ansible

This document explains how to modify the default Ansible configuration so that all connections to remote systems automatically use a specific SSH user. Instead of repeatedly specifying the user in inventories or command‑line flags, the configuration is defined once in the global Ansible configuration file.

---

## Objective

Configure Ansible to automatically use the following SSH user for all remote connections:

* **Default SSH User:** `kirsty`
* **Configuration File:** `/etc/ansible/ansible.cfg`
* **Environment:** Jump Host

The modification must be applied to the existing system configuration file rather than creating a new local configuration.

---

# Understanding the Role of ansible.cfg

Ansible behaviour is controlled through a configuration file named `ansible.cfg`. This file defines default values for various runtime parameters such as:

* Default inventory location
* SSH connection settings
* Module search paths
* Logging behaviour

By defining a default remote user in this configuration, Ansible automatically uses that account whenever it connects to remote hosts.

---

# Step 1: Identify the Active Configuration File

Verify which configuration file Ansible is currently using.

```bash
ansible --version
```

Example output includes a line similar to:

```
config file = /etc/ansible/ansible.cfg
```

This confirms that the system-wide configuration file is located at `/etc/ansible/ansible.cfg`.

---

# Step 2: Edit the Global Configuration

Because the configuration file resides inside `/etc`, administrative privileges are required to modify it.

```bash
sudo vi /etc/ansible/ansible.cfg
```

Locate the `[defaults]` section near the top of the file.

Find the `remote_user` parameter. By default it usually appears commented out.

Example of the default configuration:

```ini
#remote_user = root
```

Update it so that Ansible uses `kirsty` as the default user.

```ini
[defaults]

remote_user = kirsty
```

Save and exit the file.

---

# Step 3: Verify the Configuration

Confirm that Ansible recognizes the updated configuration.

```bash
ansible-config dump | grep REMOTE_USER
```

Expected output:

```
DEFAULT_REMOTE_USER(/etc/ansible/ansible.cfg) = kirsty
```

This indicates that Ansible will now automatically attempt to connect using the `kirsty` user unless another value overrides it.

---

# How This Affects Ansible Execution

After the configuration change, any Ansible command such as:

```bash
ansible all -m ping
```

or

```bash
ansible-playbook playbook.yml
```

will implicitly use the SSH user `kirsty` for remote connections.

This eliminates the need to include the following parameters repeatedly:

```
-u kirsty
```

or defining the user inside every inventory entry.

---

# Configuration Precedence in Ansible

Ansible determines which configuration settings to apply by checking several possible configuration locations in a fixed order. The first file found is used.

Priority order:

1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` in the current working directory
3. `~/.ansible.cfg` in the user home directory
4. `/etc/ansible/ansible.cfg` system‑wide configuration

Because this task requires modifying `/etc/ansible/ansible.cfg`, the configuration applies globally for the system unless overridden by higher‑priority configuration files.

---

# Key Outcome

The Ansible configuration has been updated so that all remote connections default to the SSH user `kirsty`. This simplifies playbook execution and removes the need to repeatedly define the SSH user in inventories or command-line options.
