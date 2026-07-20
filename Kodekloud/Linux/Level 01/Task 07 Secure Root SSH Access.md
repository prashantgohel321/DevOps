# Linux Level 1, Task 7: Disabling Direct Root SSH Login

Today's task was one of the most fundamental security hardening steps for any Linux server. My goal was to disable the ability for anyone to log in directly as the `root` user over SSH. This is a critical best practice that drastically reduces a server's vulnerability to common attacks.

This was also a perfect opportunity to compare the manual, server-by-server approach with a modern, automated solution using Ansible. This document is my detailed, first-person guide covering both methods, explaining why this security measure is so important and how to implement it efficiently.

## Table of Contents
- [The Task](#the-task)
- [Solution 1: The Manual Approach (Server by Server)](#solution-1-the-manual-approach-server-by-server)
- [Solution 2: The Automated Approach (with Ansible)](#solution-2-the-automated-approach-with-ansible)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Power of `sed` vs. the Intelligence of Ansible](#deep-dive-the-power-of-sed-vs-the-intelligence-of-ansible)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands and Modules I Used](#exploring-the-commands-and-modules-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to enhance security on all three Nautilus app servers (`stapp01`, `stapp02`, `stapp03`) by disabling direct SSH login for the `root` user.

---

### Solution 1: The Manual Approach (Server by Server)
<a name="solution-1-the-manual-approach-server-by-server"></a>
This method involves logging into each server and running the same sequence of commands.

#### The Workflow (Repeated 3 Times)
1.  **Connect to the Server:** I started by connecting to the first app server.
    ```bash
    ssh tony@stapp01
    ```

2.  **Modify the SSH Configuration:** I needed to edit the `/etc/ssh/sshd_config` file.
    -   **The Slow Way (with `vi`):** I could open the file (`sudo vi /etc/ssh/sshd_config`), search for the line containing `PermitRootLogin`, change its value to `no` (and remove the `#` if it was commented out), and then save the file.
    -   **The Fast Way (with `sed`):** A much more efficient one-liner uses the `sed` command to perform the replacement for me. This command finds any line containing `PermitRootLogin` and replaces the entire line with `PermitRootLogin no`.
        ```bash
        sudo sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        ```

3.  **Restart the SSH Service:** The change doesn't take effect until the `sshd` service is restarted.
    ```bash
    sudo systemctl restart sshd
    ```
4.  **Verification:** I checked the file to confirm the change.
    ```bash
    grep "PermitRootLogin no" /etc/ssh/sshd_config
    ```
    Seeing the correct line in the output confirmed success for that server.

I then had to `exit` and repeat this entire process for `stapp02` and `stapp03`.

---

### Solution 2: The Automated Approach (with Ansible)
<a name="solution-2-the-automated-approach-with-ansible"></a>
This is the professional, scalable solution. I performed all my work from the jump host, using Ansible to orchestrate the changes on all three app servers simultaneously.

#### 1. The Inventory (`inventory.ini`)
First, I created an "address book" for Ansible on the jump host.
```ini
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_ssh_pass=Ir0nM@n ansible_become_pass=Ir0nM@n
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_ssh_pass=Am3ric@ ansible_become_pass=Am3ric@
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_ssh_pass=BigGr33n ansible_become_pass=BigGr33n
```

#### 2. The Playbook (`playbook.yml`)
Next, I wrote a "to-do list" in YAML. This playbook is idempotent, meaning it can be run multiple times safely.
```yaml
---
- name: Harden SSH on App Servers
  hosts: app_servers
  become: yes
  tasks:
    - name: Disable root login in sshd_config
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^.*PermitRootLogin'
        line: 'PermitRootLogin no'
        state: present
      notify: restart sshd

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

#### 3. The Execution
Finally, from the jump host, I ran a single command to execute the playbook.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible then connected to all three servers and ensured the configuration was correct, restarting the SSH service only on the servers where a change was actually made.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why)"></a>
-   **Security Hardening**: This is the general term for the process of reducing a system's vulnerability by minimizing its "attack surface." Disabling direct root login is one of the first and most important hardening steps for any Linux server.
-   **Reduces Brute-Force Attacks**: The `root` username is a universal constant. By disabling it for SSH, I instantly neutralize the most common type of automated password-guessing attack.
-   **Enforces Accountability and Audit Trails**: This is the most critical reason. Forcing administrators to log in with their own named account (`tony`, `steve`) and then use `sudo` means that every privileged command is logged with the name of the user who ran it. This creates an audit trail, which is essential for security and compliance. If everyone logs in as `root`, you have no idea who did what.

---

### Deep Dive: The Power of `sed` vs. the Intelligence of Ansible
<a name="deep-dive-the-power-of-sed-vs-the-intelligence-of-ansible"></a>
This task was a perfect comparison between a simple tool and a smart tool.

-   **`sed` (The Scalpel):**
    -   `sudo sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config`
    -   **How it works:** `sed` is a "stream editor." It's a powerful command-line tool for finding and replacing text in files. My command is a "blind" operation: it finds any line with `PermitRootLogin` and replaces the whole line. It's fast and effective for a one-off change.
    -   **Limitation:** It's not idempotent. If I run it again, it will perform the same search-and-replace, even if the file is already correct. It also doesn't know that it needs to restart the SSH service afterward.

-   **Ansible `lineinfile` Module (The Smart Robot):**
    -   **How it works:** The `lineinfile` module is much more intelligent. It reads the file and checks if the line `PermitRootLogin no` already exists.
        -   If the line exists but is commented out, it will uncomment it.
        -   If the line exists with `yes`, it will change it to `no`.
        -   If the line doesn't exist at all, it will add it.
        -   If the file is already correct, it does **nothing**.
    -   **Benefit (Idempotence and Handlers):** Because it only makes a change if necessary, it's idempotent. Furthermore, the `notify: restart sshd` directive tells Ansible to trigger the `restart sshd` handler **only if a change was actually made**. This is far more efficient and safer than restarting the service every single time, even if nothing changed.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting to Restart `sshd`:** A very common mistake is to edit the `sshd_config` file and then forget to restart the service. The new security rule will not be active until the service is restarted.
-   **Incorrect `sed` command:** A faulty `sed` regular expression could accidentally delete the line or fail to replace it.
-   **Locking Yourself Out:** If I were to disable root login without first ensuring that my own user (`tony`, `steve`) had working `sudo` privileges, I could lock myself out of all administrative functions on the server.
-   **YAML Syntax Errors (Ansible):** Ansible playbooks are written in YAML, which is very sensitive to indentation. A single wrong space can cause the playbook to fail.

---

### Exploring the Commands and Modules I Used
<a name="exploring-the-commands-and-modules-i-used"></a>
#### **Manual Commands**
-   `sudo vi /etc/ssh/sshd_config`: The command to open and edit the SSH daemon's configuration file.
-   `sudo sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/' ...`: My one-liner to find and replace the necessary line. `-i` means edit **i**n-place.
-   `sudo systemctl restart sshd`: The standard command to restart a system service to apply new configuration.
-   `grep "..." [file]`: A simple command to search for and print lines that match a pattern in a file, which I used for verification.

#### **Ansible Modules**
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `lineinfile`: An Ansible module that ensures a particular line is in a file, or that a line matching a regular expression is replaced. This is perfect for managing configuration files.
-   `service`: An Ansible module for managing system services (starting, stopping, restarting).
-   `handlers`: A special section in Ansible playbooks. Handlers are tasks that only run when "notified" by another task, which is the ideal way to handle service restarts that should only happen when a configuration file has changed.
  