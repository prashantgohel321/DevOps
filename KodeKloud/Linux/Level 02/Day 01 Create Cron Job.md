# Linux Level 2, Task 1: Automation with Cron Jobs

Today's task was my first step into true Linux automation by learning about and implementing **cron jobs**. The objective was to set up a scheduled task that would run automatically on all application servers. This is the foundation for automating routine tasks like backups, system health checks, or report generation.

This was a great exercise because it wasn't just about one command; it involved installing a service, ensuring it was running, and then configuring the scheduled job itself. Repeating this across multiple servers also drove home the need for automation tools like Ansible to handle such repetitive tasks at scale. This document details both the manual method and the superior, automated Ansible approach.

## Table of Contents
- [Linux Level 2, Task 1: Automation with Cron Jobs](#linux-level-2-task-1-automation-with-cron-jobs)
  - [Table of Contents](#table-of-contents)
    - [The Task](#the-task)
    - [Solution 1: The Manual Approach (Server by Server)](#solution-1-the-manual-approach-server-by-server)
      - [The Workflow (Repeated 3 Times)](#the-workflow-repeated-3-times)
    - [Solution 2: The Automated Approach (with Ansible)](#solution-2-the-automated-approach-with-ansible)
      - [1. The Inventory (`inventory.ini`)](#1-the-inventory-inventoryini)
      - [2. The Playbook (`playbook.yml`)](#2-the-playbook-playbookyml)
      - [3. The Execution](#3-the-execution)
    - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
    - [Deep Dive: Decoding the Cron Schedule](#deep-dive-decoding-the-cron-schedule)
    - [Common Pitfalls](#common-pitfalls)
    - [Exploring the Commands and Modules I Used](#exploring-the-commands-and-modules-i-used)
      - [**Manual Commands**](#manual-commands)
      - [**Ansible Modules**](#ansible-modules)

---

### The Task
<a name="the-task"></a>
My objective was to set up a simple cron job on all three Nautilus app servers (`stapp01`, `stapp02`, `stapp03`). The requirements were:
1.  Install the `cronie` package on all app servers.
2.  Start and enable the `crond` service.
3.  For the `root` user on each server, add a cron job that runs every 5 minutes and executes the command `echo hello > /tmp/cron_text`.

---

### Solution 1: The Manual Approach (Server by Server)
<a name="solution-1-the-manual-approach-server-by-server"></a>
This method involves logging into each server individually and running the same set of commands. It's straightforward but repetitive and prone to human error.

#### The Workflow (Repeated 3 Times)
1.  **Connect to the Server:** I started by connecting to the first app server.
    ```bash
    ssh tony@stapp01
    ```

2.  **Install and Start the Cron Service:** I ensured the cron daemon was installed, running, and enabled to start on boot.
    ```bash
    sudo yum install -y cronie
    sudo systemctl start crond
    sudo systemctl enable crond
    ```

3.  **Add the Cron Job:** To edit the crontab for the `root` user, I had to use `sudo`.
    ```bash
    sudo crontab -e
    ```
    This opened a text editor (vi). I pressed `i` to enter insert mode and added the required line:
    ```
    */5 * * * * echo hello > /tmp/cron_text
    ```
    Then I pressed `Esc`, and typed `:wq` to save and quit.

4.  **Verification:** I confirmed the job was scheduled and worked correctly.
    -   **Check the schedule:** I listed the cron jobs for the `root` user.
        ```bash
        sudo crontab -l
        ```
    -   **Check the output:** I waited for up to 5 minutes for the job to execute. Then, I checked the output file.
        ```bash
        cat /tmp/cron_text
        ```
    Seeing the word "hello" in this file was the final confirmation of success.

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
Next, I wrote a "to-do list" in YAML using Ansible's built-in modules. This playbook is idempotent, meaning it can be run multiple times safely.
```yaml
---
- name: Configure Cron Jobs on App Servers
  hosts: app_servers
  become: yes
  tasks:
    - name: Ensure cronie package is installed
      ansible.builtin.package:
        name: cronie
        state: present

    - name: Ensure crond service is running and enabled
      ansible.builtin.service:
        name: crond
        state: started
        enabled: yes

    - name: Add cron job for root user
      ansible.builtin.cron:
        name: "echo hello message"
        minute: "*/5"
        user: root
        job: "echo hello > /tmp/cron_text"
        state: present
```

#### 3. The Execution
Finally, from the jump host, I ran a single command to execute the playbook.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible then connected to all three servers and made sure the package was installed, the service was running, and the cron job was present, completing the task for the entire fleet in seconds.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`cron`**: This is the classic, time-tested utility for scheduling commands on Linux. The service that runs in the background is called the **cron daemon (`crond`)**. It wakes up every minute, checks the schedule, and runs any jobs that are due.
-   **`cronie`**: This is the specific software package on modern Red Hat-based systems (like CentOS) that provides the `crond` service and the `crontab` command.
-   **`crontab`**: This stands for "cron table." It's a special file that contains the list of scheduled jobs for a user. Using the `crontab -e` command is the correct and safe way to edit this file, as it checks for syntax errors before saving.
-   **Running as `root`**: Many system administration tasks (like backups or system updates) need to be run with elevated privileges. By using `sudo crontab -e`, I was editing the crontab for the system's most powerful user.

---

### Deep Dive: Decoding the Cron Schedule
<a name="deep-dive-decoding-the-cron-schedule"></a>
The `*/5 * * * *` part can look cryptic, but it follows a simple pattern. There are five fields, representing different units of time.
[Image of cron syntax breakdown]
```
.---------------- minute (0 - 59)
|  .------------- hour (0 - 23)
|  |  .---------- day of month (1 - 31)
|  |  |  .------- month (1 - 12)
|  |  |  |  .---- day of week (0 - 6) (Sunday to Saturday)
|  |  |  |  |
* * * * * <-- command to be executed
```
-   A `*` means "every".
-   `*/5` in the minute field means "at every 5th minute past the hour" (i.e., at :00, :05, :10, etc.).

So, `*/5 * * * *` translates to: "At every 5th minute, of every hour, on every day-of-month, of every month, on every day-of-week."

---

### Common Pitfalls
<a name="common-pitfalls"></a>
-   **Editing the Wrong Crontab:** A common mistake is forgetting `sudo` when you intend to add a job for the `root` user. Running `crontab -e` without `sudo` edits the crontab for your current user (e.g., `tony`), not `root`.
-   **Path Issues:** Cron jobs run in a very minimal environment and don't have the same `PATH` as an interactive shell. It's a best practice to always use absolute paths for commands and scripts (e.g., `/usr/bin/echo` instead of just `echo`) to avoid "command not found" errors.
-   **Forgetting to Restart Service:** While not needed for adding a cron job, if I were to change a system-wide cron configuration file (like `/etc/cron.d/`), I would need to restart the `crond` service for the changes to take effect.

---

### Exploring the Commands and Modules I Used
<a name="exploring-the-commands-and-modules-i-used"></a>
#### **Manual Commands**
-   `sudo yum install -y cronie`: Installs the cron service package.
-   `sudo systemctl start/enable crond`: Manages the cron daemon service.
-   `sudo crontab -e`: **E**dits the crontab for the `root` user.
-   `sudo crontab -l`: **L**ists the crontab for the `root` user.
-   `cat /tmp/cron_text`: Displays the content of the output file to verify the job ran.

#### **Ansible Modules**
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `ansible.builtin.package`: The Ansible module for managing software packages. `state: present` ensures the package is installed.
-   `ansible.builtin.service`: The Ansible module for managing system services. `state: started` and `enabled: yes` ensures the service is running now and on boot.
-   `ansible.builtin.cron`: The official Ansible module for managing cron jobs. It's the correct, idempotent way to manage scheduled tasks. It's much smarter than just echoing a line into a file, as it will check if the job already exists and only add or modify it if necessary.
   
