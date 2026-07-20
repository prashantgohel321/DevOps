# Ansible Level 04 Day 04: Setup HTTPD and PHP

This document outlines the solution for Ansible Level 04 Day 04. The objective was to write a playbook to install an Apache web server alongside PHP on App Server 1, reconfigure its default DocumentRoot, and deploy a template file.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Verify the Environment](#1-verify-the-environment)
    * [2. Create the Playbook](#2-create-the-playbook)
    * [3. Execute and Validate](#3-execute-and-validate)
3.  [Deep Dive: Ansible Concepts Used](#deep-dive-ansible-concepts-used)
    * [Multi-Package Installation](#multi-package-installation)
    * [Configuration Management (`replace`)](#configuration-management-replace)
    * [Order of Operations](#order-of-operations)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Deploy and configure a LAMP-style (without DB) stack on App Server 1 using a single playbook.

**Requirements:**
1.  **Target:** App Server 1 (`stapp01`).
2.  **Playbook:** `~/playbooks/httpd.yml`.
3.  **Packages:** Install `httpd` and `php` (default repo versions).
4.  **Configuration:** Change the Apache `DocumentRoot` in `/etc/httpd/conf/httpd.conf` to `/var/www/html/myroot`.
5.  **Directory:** Ensure the directory `/var/www/html/myroot` actually exists.
6.  **Template:** Copy the existing `~/playbooks/templates/phpinfo.php.j2` template to the new document root as `phpinfo.php`. Owner/Group must be `apache`.
7.  **Service:** Start and enable the `httpd` service.
8.  **Execution:** Run strictly using `ansible-playbook -i inventory httpd.yml`.

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Verify the Environment
<a name="1-verify-the-environment"></a>
Before starting, ensure you are in the correct directory and that the inventory and templates exist.

**Command:**
```bash
cd ~/playbooks
ls -l inventory
ls -l templates/phpinfo.php.j2
```

### 2. Create the Playbook
<a name="2-create-the-playbook"></a>
Create the playbook to execute the requirements sequentially. We require `become: yes` because installing packages and modifying files in `/etc` and `/var` require root privileges.

**Command:**
```bash
vi httpd.yml
```

**Content:**
```yaml
---
- name: Setup Apache and PHP on App Server 1
  hosts: stapp01
  become: yes
  tasks:
    - name: Install httpd and php packages
      yum:
        name:
          - httpd
          - php
        state: present

    - name: Ensure custom DocumentRoot directory exists
      file:
        path: /var/www/html/myroot
        state: directory
        owner: apache
        group: apache
        mode: '0755'

    - name: Change DocumentRoot path in httpd.conf
      replace:
        path: /etc/httpd/conf/httpd.conf
        regexp: 'DocumentRoot "/var/www/html"'
        replace: 'DocumentRoot "/var/www/html/myroot"'

    - name: Change Directory block in httpd.conf
      replace:
        path: /etc/httpd/conf/httpd.conf
        regexp: '<Directory "/var/www/html">'
        replace: '<Directory "/var/www/html/myroot">'

    - name: Copy phpinfo template to the new DocumentRoot
      template:
        src: templates/phpinfo.php.j2
        dest: /var/www/html/myroot/phpinfo.php
        owner: apache
        group: apache

    - name: Start and enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes
```

### 3. Execute and Validate
<a name="3-execute-and-validate"></a>
Run the playbook using the standard command requested.

**Execution Command:**
```bash
ansible-playbook -i inventory httpd.yml
```

**Expected Output:**
```text
PLAY [Setup Apache and PHP on App Server 1] *****************************************

TASK [Gathering Facts] **************************************************************
ok: [stapp01]

TASK [Install httpd and php packages] ***********************************************
changed: [stapp01]

TASK [Ensure custom DocumentRoot directory exists] **********************************
changed: [stapp01]

TASK [Change DocumentRoot path in httpd.conf] ***************************************
changed: [stapp01]

TASK [Change Directory block in httpd.conf] *****************************************
changed: [stapp01]

TASK [Copy phpinfo template to the new DocumentRoot] ********************************
changed: [stapp01]

TASK [Start and enable httpd service] ***********************************************
changed: [stapp01]

PLAY RECAP **************************************************************************
stapp01                    : ok=7    changed=6    unreachable=0    failed=0    ...
```

**Manual Verification (Optional):**
To ensure the setup works, you can `curl` the server from the jump host.
```bash
ansible stapp01 -i inventory -a "curl http://localhost/phpinfo.php"
```
*(If PHP is correctly configured, it will return the HTML output of the phpinfo function).*

---

## Deep Dive: Ansible Concepts Used
<a name="deep-dive-ansible-concepts-used"></a>

### Multi-Package Installation
Instead of writing two separate `yum` tasks for `httpd` and `php`, you can pass a list directly to the `name` parameter in the `yum` module. This is cleaner and executes faster as Ansible can pass the entire list to the underlying package manager in a single transaction.

### Configuration Management (`replace`)
<a name="configuration-management-replace"></a>
To change the DocumentRoot safely without completely overwriting the `httpd.conf` file (which would destroy other default settings), we use the `replace` module.
* We must target both the actual `DocumentRoot "/var/www/html"` directive and the corresponding `<Directory "/var/www/html">` permissions block. 
* Failing to update the `<Directory>` block would result in Apache throwing a "403 Forbidden" error when trying to access the new `/var/www/html/myroot` folder.

### Order of Operations
<a name="order-of-operations"></a>
The tasks are intentionally ordered:
1.  **Packages:** `httpd` must be installed first so that the `apache` user/group exists, and the `/etc/httpd/` config directory is created.
2.  **Directories:** `/var/www/html/myroot` is created using the newly available `apache` user.
3.  **Configs & Files:** `httpd.conf` is modified, and the `.php` file is placed inside the new directory.
4.  **Service:** Finally, the service is started. If we started the service before changing the config, we would need to add a "handler" to restart Apache after the config changes. By starting it at the very end, it boots up utilizing our modifications immediately.
  
