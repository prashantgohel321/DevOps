# Ansible Level 04 Day 02: Create Users and Groups

This document outlines the solution for Ansible Level 04 Day 02. The objective was to onboard new team members by creating user accounts, assigning them to specific groups (`admins` and `developers`), setting custom home directories, and securely applying passwords using Ansible Vault.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Configure Ansible for Vault](#1-configure-ansible-for-vault)
    * [2. Encrypt the Passwords](#2-encrypt-the-passwords)
    * [3. Create the Playbook](#3-create-the-playbook)
    * [4. Execute and Validate](#4-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    * [Ansible Vault & `ansible.cfg`](#ansible-vault--ansiblecfg)
    * [Password Hashing in Ansible](#password-hashing-in-ansible)
    * [Loading Variable Files (`vars_files`)](#loading-variable-files-vars_files)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Create users and groups on App Server 2 (`stapp02`) based on a provided YAML list, applying specific constraints and secure passwords.

**Requirements:**
1.  **Target:** App Server 2.
2.  **Groups to Create:** `developers` and `admins`.
3.  **Data Source:** `~/playbooks/data/users.yml` (contains lists of users for each group).
4.  **Developers Group:** * Home Directory: `/var/www` (exact path, not `/var/www/user`).
    * Password: `Rc5C9EyvbU` (Must be encrypted).
5.  **Admins Group:**
    * Home Directory: Default (`/home/{USER}`).
    * Password: `YchZHRcLkL` (Must be encrypted).
    * Privileges: Must be added to the `wheel` group for sudo access.
6.  **Vault:** Use `~/playbooks/secrets/vault.txt` as the vault password file. Configure `ansible.cfg` to use this file automatically.
7.  **Playbook:** `~/playbooks/add_users.yml`. Must run with `ansible-playbook -i inventory add_users.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Configure Ansible for Vault
<a name="1-configure-ansible-for-vault"></a>
Since the validation script will run the playbook *without* the `--vault-password-file` argument, we must configure Ansible to find the vault password automatically.

**Command:**
```bash
cd ~/playbooks
vi ansible.cfg
```

**Content:**
```ini
[defaults]
inventory = ./inventory
vault_password_file = ./secrets/vault.txt
```
*(Ensure you preserve any other existing settings in the file if they were already there, just add/modify the `vault_password_file` line).*

### 2. Encrypt the Passwords
<a name="2-encrypt-the-passwords"></a>
Instead of writing plain text passwords in our playbook, we will create a dedicated secrets file, encrypt it with Ansible Vault, and load it into our playbook.

**Create the secrets file:**
```bash
vi secrets.yml
```

**Initial Content (Plain Text):**
```yaml
dev_pass_plain: "Rc5C9EyvbU"
admin_pass_plain: "YchZHRcLkL"
```

**Encrypt the file:**
Run the following command. Because we configured `ansible.cfg` in Step 1, Ansible will automatically use `vault.txt` to encrypt this file without prompting you for a password.
```bash
ansible-vault encrypt secrets.yml
```
*(If you `cat secrets.yml` now, you will see it is fully encrypted with `$ANSIBLE_VAULT` headers).*

### 3. Create the Playbook
<a name="3-create-the-playbook"></a>
Now we construct the playbook. We use `vars_files` to pull in the user lists from `data/users.yml` and the encrypted passwords from `secrets.yml`. 

*Note: The structure of `data/users.yml` typically defines two lists: `developers:` and `admins:`. We will loop over these.*

**Command:**
```bash
vi add_users.yml
```

**Content:**
```yaml
---
- name: Create Users and Groups for Nautilus Project
  hosts: stapp02
  become: yes
  vars_files:
    - data/users.yml
    - secrets.yml
  tasks:
    - name: Create developers group
      group:
        name: developers
        state: present

    - name: Create admins group
      group:
        name: admins
        state: present

    - name: Add users to developers group
      user:
        name: "{{ item }}"
        group: developers
        home: /var/www
        password: "{{ dev_pass_plain | password_hash('sha512') }}"
        state: present
      loop: "{{ developers }}"
      # Note: If your users.yml nests them under a parent key (e.g., users: developers:), 
      # adjust this loop to "{{ users.developers }}"

    - name: Add users to admins group
      user:
        name: "{{ item }}"
        group: admins
        groups: wheel
        append: yes
        password: "{{ admin_pass_plain | password_hash('sha512') }}"
        state: present
      loop: "{{ admins }}"
      # Note: Adjust to "{{ users.admins }}" if nested under a parent 'users' key.
```

### 4. Execute and Validate
<a name="4-execute-and-validate"></a>
Run the playbook. Thanks to our `ansible.cfg`, we don't need any extra arguments.

**Execution Command:**
```bash
ansible-playbook -i inventory add_users.yml
```

**Expected Output:**
You should see tasks executing successfully, creating groups, and dynamically looping over the lists to create the users.

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Ansible Vault & `ansible.cfg`
<a name="ansible-vault--ansiblecfg"></a>
Storing plain text passwords in Git or playbooks is a massive security risk. **Ansible Vault** encrypts variables and files. By defining `vault_password_file` in `ansible.cfg`, you streamline automation. The CI/CD pipeline (or the validation script, in this case) just needs access to that file to decrypt on the fly, keeping the execution command perfectly clean.

### Password Hashing in Ansible
<a name="password-hashing-in-ansible"></a>
The Ansible `user` module's `password` parameter does **not** accept plain text passwords. If you pass plain text, Linux will literally store that text in `/etc/shadow`, rendering the account un-loggable because the system expects a hash there. 
By applying the Jinja2 filter `| password_hash('sha512')`, Ansible takes our decrypted plain-text string from the vault, hashes it using the SHA-512 algorithm, and feeds the resulting secure hash to the Linux system.

### Loading Variable Files (`vars_files`)
<a name="loading-variable-files-vars_files"></a>
Instead of hardcoding lists of users inside the playbook, we imported an external data file (`data/users.yml`). This is excellent practice because it separates **Data** from **Logic**. If HR hires a new developer tomorrow, you only update `users.yml`—the playbook logic (`add_users.yml`) remains completely untouched.
   
