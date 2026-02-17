# Linux Level 1, Task 17: Setting User Resource Limits

Today's task was a critical exercise in ensuring server stability and preventing resource exhaustion. My objective was to impose limits on the number of processes a specific user could run. This is a common and important task for a system administrator to prevent a single user or a faulty application from overwhelming the server and causing a crash.

I learned how to make these limits persistent by editing the `/etc/security/limits.conf` file. This was also a perfect opportunity to contrast the simple manual approach with a more robust and scalable solution using Ansible. This document is my first-person guide to both methods.

### The Task

My objective was to set resource limits for the `nfsuser` on the **Storage Server**. The specific requirements were:
-   Set the **soft limit** for the maximum number of processes (`nproc`) to **1024**.
-   Set the **hard limit** for the maximum number of processes (`nproc`) to **2025**.

### Solution 1: The Manual Approach

This method involves logging into the server and directly editing the configuration file.

#### The Workflow
1.  **Connect to the Server:** I first logged into the Storage Server (`ssh natasha@ststor01`).

2.  **Edit the Configuration File:** I opened the `/etc/security/limits.conf` file using `sudo` and a text editor.
    ```bash
    sudo vi /etc/security/limits.conf
    ```

3.  **Add the Limits:** At the bottom of the file, I added the two required lines to define the soft and hard limits for the `nfsuser`.
    ```
    # Set limits for nfsuser
    nfsuser   soft   nproc   1024
    nfsuser   hard   nproc   2025
    ```

4.  **Verification:** I saved the file and then used `grep` to confirm that my changes were correctly saved.
    ```bash
    grep nfsuser /etc/security/limits.conf
    ```
    The output showed the two lines I had added, which was the definitive proof that my task was successful. These limits will apply the next time `nfsuser` starts a new session.

---

### Solution 2: The Automated Approach (with Ansible)

This is the professional, scalable solution. I would perform all work from the jump host, using Ansible to apply the configuration.

#### 1. The Inventory (`inventory.ini`)
First, I would define the target server in an inventory file on the jump host.
```ini
[storage_server]
ststor01 ansible_host=172.16.238.15 ansible_user=natasha ansible_ssh_pass=Bl@kW ansible_become_pass=Bl@kW
```

#### 2. The Playbook (`playbook.yml`)
Next, I would write a playbook using Ansible's dedicated `pam_limits` module, which is the correct, idempotent way to manage this file.
```yaml
---
- name: Configure Resource Limits on Storage Server
  hosts: storage_server
  become: yes
  tasks:
    - name: Set nproc soft limit for nfsuser
      ansible.posix.pam_limits:
        domain: nfsuser
        limit_type: soft
        limit_item: nproc
        value: 1024

    - name: Set nproc hard limit for nfsuser
      ansible.posix.pam_limits:
        domain: nfsuser
        limit_type: hard
        limit_item: nproc
        value: 2025
```

#### 3. The Execution
Finally, from the jump host, I would run a single command to apply the configuration.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible would connect to the server and ensure those exact lines are present in `/etc/security/limits.conf`, adding or modifying them only if necessary.

---

### Key Concepts (The "What & Why")

-   **Resource Limits (`ulimit`)**: This is a feature of the Linux kernel that allows administrators to control the resources available to a user or process. This is a critical tool for maintaining server stability. Without limits, a buggy script or a malicious user could start a "fork bomb" (a process that endlessly replicates itself), consume all available Process IDs (PIDs) or memory, and crash the entire system.
-   **`nproc`**: This specific limit controls the maximum **n**umber of **proc**esses that a user can own at one time.
-   **Soft vs. Hard Limits**: This provides a flexible but controlled system.
    -   A **Soft Limit** is the effective limit that is currently enforced. A user can choose to temporarily raise their own soft limit (using the `ulimit` command), but only up to the ceiling set by the hard limit.
    -   A **Hard Limit** is the absolute maximum value for a resource. It acts as a safety net and can only be raised by the `root` user.
-   **`/etc/security/limits.conf`**: While the `ulimit` command can set limits for a user's *current session*, these limits are temporary. The `limits.conf` file is where you define **permanent**, system-wide resource limits that are applied every time a user logs in.

### Commands and Modules I Used

#### **Manual Commands**
-   `sudo vi /etc/security/limits.conf`: The command to open and edit the system-wide resource limits configuration file.
-   `grep nfsuser /etc/security/limits.conf`: My verification command. It searches for and prints all lines containing the word "nfsuser" in the file, proving my changes were saved.

#### **Ansible Modules**
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `ansible.posix.pam_limits`: The official Ansible module for managing resource limits in the `/etc/security/limits.conf` file. It's the correct, idempotent way to manage these settings, as it will only make a change if the current configuration doesn't match the desired state.
  