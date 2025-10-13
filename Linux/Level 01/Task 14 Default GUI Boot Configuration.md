# Linux Level 1, Task 14: Changing the Default Boot Target

Today's task was a fundamental system administration skill: changing the default boot target (or "runlevel") of a server. My goal was to reconfigure all app servers to boot into a graphical user interface (GUI) by default, instead of the standard command-line interface.

This exercise was a perfect opportunity to contrast the repetitive manual approach with a powerful, automated solution using Ansible. This document is my first-person guide, detailing both methods and explaining the concepts behind systemd targets.

### The Task

My objective was to change the default boot behavior on **all three Nautilus app servers**. The specific requirements were:
-   Set the default boot target to the graphical user interface.
-   Do **not** reboot the servers after making the change.

### Solution 1: The Manual Approach (Server by Server)

This method involves logging into each server individually and running the same commands. It's direct but not scalable.

#### The Workflow (Repeated 3 Times)
1.  **Connect to the Server:** I started by connecting to the first app server.
    ```bash
    ssh tony@stapp01
    ```

2.  **Check the Current Default:** I used `systemctl` to see the current default boot target.
    ```bash
    systemctl get-default
    # Output: multi-user.target
    ```
    This confirmed the server was set to boot into the command line.

3.  **Set the New Default:** This was the core of the task. I set the new default to `graphical.target`.
    ```bash
    sudo systemctl set-default graphical.target
    ```
    This command creates a symbolic link that `systemd` reads on the next boot.

4.  **Verification:** I ran the `get-default` command again to confirm the change was made successfully.
    ```bash
    systemctl get-default
    # Output: graphical.target
    ```
    Seeing this output was the definitive proof of success for that server.

I then had to `exit` and repeat this entire process for `stapp02` and `stapp03`.

---

### Solution 2: The Automated Approach (with Ansible)

This is the professional, scalable solution. I performed all my work from the jump host, using Ansible to orchestrate the change on all three app servers at once.

#### 1. The Inventory (`inventory.ini`)
First, I created an "address book" for Ansible on the jump host.
```ini
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_ssh_pass=Ir0nM@n ansible_become_pass=Ir0nM@n
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_ssh_pass=Am3ric@ ansible_become_pass=Am3ric@
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_ssh_pass=BigGr33n ansible_become_pass=BigGr33n
```

#### 2. The Playbook (`playbook.yml`)
Next, I wrote a simple "to-do list" in YAML.
```yaml
---
- name: Set Default Boot Target to Graphical
  hosts: app_servers
  become: yes
  tasks:
    - name: Set default target to graphical.target
      ansible.builtin.command:
        cmd: systemctl set-default graphical.target
```

#### 3. The Execution
Finally, from the jump host, I ran a single command to execute the playbook.
```bash
ansible-playbook -i inventory.ini playbook.yml
```
Ansible then connected to all three servers and ran the command, completing the task for the entire fleet in seconds.

---

### Key Concepts (The "What & Why")

-   **Runlevels and systemd Targets**: These define the state a Linux system boots into.
    -   In older systems, these were numeric "runlevels" (e.g., runlevel 3 for text, 5 for GUI).
    -   In modern systems using `systemd`, these are descriptive "targets." A target is a collection of systemd units that should be started to reach a certain state.
-   **`multi-user.target`**: This is the standard target for a server. It starts all the necessary networking and system services to allow multiple users to log in via the command line, but it does **not** start a graphical display manager. This is efficient and uses minimal resources.
-   **`graphical.target`**: This target includes everything in `multi-user.target` and adds the services needed to run a full graphical desktop environment (like GNOME or KDE). This is the standard for desktop Linux distributions but is less common on servers unless specific GUI-based tools are required.
-   **`systemctl set-default`**: This is the command used to change the default target for the next boot. It works by creating a symbolic link at `/etc/systemd/system/default.target` that points to the desired target file (e.g., `/usr/lib/systemd/system/graphical.target`). It does **not** change the current running state, which is why a reboot was not required for this task.

### Commands I Used

#### **Manual Commands**
-   `systemctl get-default`: A command to check the currently configured default boot target. I used this for both initial investigation and final verification.
-   `sudo systemctl set-default graphical.target`: The main command for this task. It sets the default boot target for `systemd` to the graphical environment.

#### **Ansible Modules**
-   `ansible-playbook -i [inventory] [playbook]`: The main command to run an Ansible playbook.
-   `ansible.builtin.command`: An Ansible module that allows you to run a simple shell command on the remote host(s). While there are more specific modules for managing `systemd`, this is a direct and effective way to run the `set-default` command. `become: yes` was used in the playbook to ensure the command was run with `sudo`.
   