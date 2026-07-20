# Ansible Level 03 Day 05: Ansible Replace Module

This document outlines the solution for Ansible Level 03 Day 05. The objective was to write an Ansible playbook that modifies the contents of specific text files across multiple application servers. This task highlights the capability of the `replace` module to perform targeted string substitutions.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Verify the Environment](#1-verify-the-environment)
    * [2. Create the Playbook](#2-create-the-playbook)
    * [3. Execute and Validate](#3-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    * [The `replace` Module](#the-replace-module)
    * [Multiple Plays in One Playbook](#multiple-plays-in-one-playbook)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Use the Ansible `replace` module to substitute specific strings in files spread across different app servers.

**Requirements:**
1.  **Playbook Location:** `/home/thor/ansible/playbook.yml` on the jump host.
2.  **App Server 1 (`stapp01`):** In file `/opt/devops/blog.txt`, replace `xFusionCorp` with `Nautilus`.
3.  **App Server 2 (`stapp02`):** In file `/opt/devops/story.txt`, replace `Nautilus` with `KodeKloud`.
4.  **App Server 3 (`stapp03`):** In file `/opt/devops/media.txt`, replace `KodeKloud` with `xFusionCorp Industries`.
5.  **Constraint:** Must run successfully using `ansible-playbook -i inventory playbook.yml` without any extra CLI arguments.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Since the inventory file is already provided, quickly review it to ensure it contains the required hostnames (`stapp01`, `stapp02`, `stapp03`) and their respective connection variables.

**Command:**
```bash
cd /home/thor/ansible
cat inventory
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create a YAML playbook structured with three distinct plays. This approach cleanly targets each server individually and applies the corresponding file path and string replacement logic required for that specific server. Modifying files under `/opt` requires elevated privileges, so `become: yes` must be included.

**Command:**
```bash
vi playbook.yml
```

**Content:**
```yaml
---
- name: Update data on App Server 1
  hosts: stapp01
  become: yes
  tasks:
    - name: Replace xFusionCorp with Nautilus in blog.txt
      replace:
        path: /opt/devops/blog.txt
        regexp: 'xFusionCorp'
        replace: 'Nautilus'

- name: Update data on App Server 2
  hosts: stapp02
  become: yes
  tasks:
    - name: Replace Nautilus with KodeKloud in story.txt
      replace:
        path: /opt/devops/story.txt
        regexp: 'Nautilus'
        replace: 'KodeKloud'

- name: Update data on App Server 3
  hosts: stapp03
  become: yes
  tasks:
    - name: Replace KodeKloud with xFusionCorp Industries in media.txt
      replace:
        path: /opt/devops/media.txt
        regexp: 'KodeKloud'
        replace: 'xFusionCorp Industries'
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
PLAY [Update data on App Server 1] **************************************************
...
changed: [stapp01]

PLAY [Update data on App Server 2] **************************************************
...
changed: [stapp02]

PLAY [Update data on App Server 3] **************************************************
...
changed: [stapp03]

PLAY RECAP **************************************************************************
stapp01                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp02                    : ok=2    changed=1    unreachable=0    failed=0    ...
stapp03                    : ok=2    changed=1    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
To verify the content of the files on the remote servers, use ad-hoc commands:
```bash
ansible stapp01 -i inventory -m command -a "cat /opt/devops/blog.txt" --become
ansible stapp02 -i inventory -m command -a "cat /opt/devops/story.txt" --become
ansible stapp03 -i inventory -m command -a "cat /opt/devops/media.txt" --become
```

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### The `replace` Module
<a name="the-replace-module"></a>
The `replace` module is designed to replace all instances of a particular string in a file based on a regular expression.
* **`path`**: The absolute path to the file on the remote machine that needs to be modified.
* **`regexp`**: The regular expression (or string, as used in this scenario) to look for in every line of the file.
* **`replace`**: The string to substitute into the file wherever the `regexp` matches.
* **Idempotency:** If the string specified in `regexp` is no longer found in the file (e.g., because the playbook was already run), Ansible will correctly report `ok` instead of `changed`, ensuring no unintended side effects.

### Multiple Plays in One Playbook
<a name="multiple-plays-in-one-playbook"></a>
Instead of using conditionals (`when`) under a single `hosts: all` declaration, defining multiple discrete plays (one for each `hosts: stapp0X`) is often cleaner when entirely different actions, paths, and values apply to entirely different servers. This keeps the YAML easily readable and self-documenting.
   
