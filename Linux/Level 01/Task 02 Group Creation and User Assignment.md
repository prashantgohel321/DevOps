# Linux Level 1, Task 2: Managing Users and Groups Across Multiple Servers

Today's task was a perfect demonstration of a fundamental system administration responsibility: managing user and group access across a fleet of servers. The objective was to create a new group and add a user to it on all three app servers.

This exercise was incredibly valuable because it highlighted the difference between performing a task **manually** versus **automating** it. I'll detail both methods below. The manual process showed me the raw commands, but the automated Ansible approach revealed the power, speed, and reliability of Infrastructure as Code. This document is my detailed, first-person guide to both solutions.

## Table of Contents
- [The Task](#the-task)
- [Solution 1: The Manual Approach (Server by Server)](#solution-1-the-manual-approach-server-by-server)
- [Solution 2: The Automated Approach (with Ansible)](#solution-2-the-automated-approach-with-ansible)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Power of Automation vs. Manual Repetition](#deep-dive-the-power-of-automation-vs-manual-repetition)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands and Modules I Used](#exploring-the-commands-and-modules-i-used)

---

### The Task
<a name="the-task"></a>
My objective was to ensure consistent user and group configuration across all three Nautilus app servers. The specific requirements were:
1.  Create a new group named `nautilus_admin_users` on all app servers.
2.  Add the user `stark` to this new group on all app servers.
3.  If the `stark` user didn't exist, I had to create it first.

---

### Solution 1: The Manual Approach (Server by Server)
<a name="solution-1-the-manual-approach-server-by-server"></a>
This method involves logging into each server individually and running the same set of commands. It's straightforward but repetitive.

#### The Workflow (Repeated 3 Times)
1.  **Connect to the Server:** I started by connecting to the first app server.
    ```bash
    ssh tony@stapp01
    ```

2.  **Create the Group:** I used `groupadd` to create the new group.
    ```bash
    sudo groupadd nautilus_admin_users
    ```
    *(If the group already existed, this command would give a harmless error that I could ignore).*

3.  **Create the User:** I ensured the user existed with `useradd`.
    ```bash
    sudo useradd stark
    ```
    *(Similarly, if the user already existed, this would give a harmless error).*

4.  **Add User to Group:** This was the main step. I used `usermod` to add the user to the group. The `-aG` flags are critical here.
    ```bash
    sudo usermod -aG nautilus_admin_users stark
    ```

5.  **Verification:** I confirmed my changes using the `id` command.
    ```bash
    id stark
    ```
    The output listed `nautilus_admin_users` in the `groups=` section, proving my success on that server.

I then had to `exit` and repeat this entire process for `stapp02` and `stapp03`.

---

### Solution 2: The Automated Approach (with Ansible)
<a name="solution-2-the-automated-approach-with-ansible"></a>
This is the professional, scalable solution. Instead of logging into each server, I performed all my work from the jump host, using Ansible to orchestrate the changes on all three app servers simultaneously.

#### 1. The Inventory (`inventory.ini`)
First, I created an "address book" for Ansible on the jump host, telling it which servers to manage.
```ini
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_ssh_pass=Ir0nM@n
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_ssh_pass=Am3ric@
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_ssh_pass=BigGr33n
```

#### 2. The Playbook (`playbook.yml`)
Next, I wrote a "to-do list" in YAML. This playbook is idempotent, meaning it can be run multiple times safely.
```yaml
---
- name: Configure Users and Groups on App Servers
  hosts: app_servers
  become: yes
  tasks:
    - name: Ensure nautilus_admin_users group exists
      ansible.builtin.group:
        name: nautilus_admin_users
        state: present

    - name: Ensure stark user exists and is in the admin group
      ansible.builtin.user:
        name: stark
        groups: nautilus_admin_users
        append: yes
        state: present
```

#### 3. The Execution
Finally, from the jump host, I ran a single command to execute the playbook.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible then connected to all three servers and made sure the group and user existed and that the user was in the group. The entire task was completed in seconds.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **Users and Groups**: These are the fundamental building blocks of Linux security.
    -   A **user** is an identity that can own files and run processes.
    -   A **group** is a collection of users. Granting permissions to a group is far more efficient than granting them to individual users. By adding `stark` to `nautilus_admin_users`, I've given him a specific role that can be managed centrally.
-   **`usermod -aG`**: This command is critical.
    -   `-G`: Specifies the **G**roup(s) to add the user to.
    -   `-a`: Stands for **a**ppend. This is extremely important. Without `-a`, the `usermod` command would *replace* all of the user's existing groups with the new one. The `-a` flag ensures the user is added to the new group while keeping all their other group memberships.
-   **Ansible**: This is a powerful automation tool that allows me to manage the configuration of multiple servers from a single control node. It's "agentless," meaning it just uses standard SSH to connect. It's the perfect tool for ensuring a consistent state across an entire fleet of servers.

---

### Deep Dive: The Power of Automation vs. Manual Repetition
<a name="deep-dive-the-power-of-automation-vs-manual-repetition"></a>
This task was the perfect illustration of why DevOps relies on automation.

-   **The Manual Way:**
    -   **Slow:** Logging into each server, typing commands, and verifying takes time. For 3 servers it's tedious; for 300 it's impossible.
    -   **Error-Prone:** I could make a typo on one server, forget a step, or use the wrong flag (`usermod -G` instead of `-aG`). This leads to an inconsistent environment that is very hard to debug later.
    -   **Not Scalable:** This process does not scale.

-   **The Ansible Way:**
    -   **Fast:** Ansible runs its tasks on all servers in parallel. The entire operation takes seconds.
    -   **Consistent:** The playbook is a single source of truth. It guarantees that the exact same configuration is applied to every single server, every single time.
    -   **Idempotent:** I can run the same playbook a hundred times. If the user and group are already correct, Ansible will check the state and make no changes. This makes it safe to run automation repeatedly.
    -   **Self-Documenting:** The playbook itself is a human-readable document that describes the desired state of my servers.

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Forgetting `sudo` (Manual):** All user and group management commands require root privileges.
-   **Forgetting `-a` in `usermod` (Manual):** The most dangerous mistake. Using `usermod -G` instead of `usermod -aG` can strip a user of important group memberships and break their access to the system.
-   **Forgetting a Server (Manual):** It's easy to lose track and accidentally miss configuring one of the servers.
-   **YAML Syntax Errors (Ansible):** Ansible playbooks are written in YAML, which is very sensitive to indentation. A single wrong space can cause the playbook to fail.

---

### Exploring the Commands and Modules I Used
<a name="exploring-the-commands-and-modules-i-used"></a>
#### **Manual Commands**
-   `sudo groupadd [group_name]`: Creates a new group.
-   `sudo useradd [user_name]`: Creates a new user with default settings.
-   `sudo usermod -aG [group_name] [user_name]`: Modifies a user to **a**ppend them to a new **G**roup.
-   `id [user_name]`: Displays the UID, GID, and all group memberships for a user. My primary verification tool.
-   `getent group [group_name]`: Gets the entry for a group from the system's database, showing its GID and all its members.

#### **Ansible Modules**
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `ansible.builtin.group`: The Ansible module for managing groups. `state: present` ensures the group exists.
-   `ansible.builtin.user`: The Ansible module for managing users. `state: present` ensures the user exists, and `groups:` with `append: yes` adds them to the specified groups.
   