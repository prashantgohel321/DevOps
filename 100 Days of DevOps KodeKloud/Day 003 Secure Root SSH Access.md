# DevOps Day 03 — Disabling Direct Root SSH Login 

<br>
<br>

- [DevOps Day 03 — Disabling Direct Root SSH Login](#devops-day-03--disabling-direct-root-ssh-login)
  - [Real Scenario](#real-scenario)
- [Understanding the Requirement](#understanding-the-requirement)
- [How SSH Login Works Internally](#how-ssh-login-works-internally)
- [Step 1 — Editing the SSH Configuration](#step-1--editing-the-ssh-configuration)
- [Step 2 — Restarting the SSH Service](#step-2--restarting-the-ssh-service)
- [Understanding the SSH Daemon](#understanding-the-ssh-daemon)
- [Why Disabling Root SSH Login Is Important](#why-disabling-root-ssh-login-is-important)
- [Understanding the PermitRootLogin Directive](#understanding-the-permitrootlogin-directive)
- [Additional Useful Commands](#additional-useful-commands)
- [Practical Outcome](#practical-outcome)

<br>
<br>

## Real Scenario

- When a Linux server is connected to a network, especially the internet, one of the first services exposed is usually **SSH (Secure Shell)**. SSH allows administrators to connect to the server remotely and manage it from another machine.

- However, SSH also becomes a primary target for attackers. Automated bots constantly scan servers and attempt to log in by guessing usernames and passwords. The most common target is the **root account**, because every Linux system has it and it has unlimited privileges.

- For this reason, a common security hardening practice is to **disable direct root login via SSH**. Instead of logging in as root, administrators log in using their personal accounts and then elevate privileges using `sudo`.

- In this task, the objective was to disable root login through SSH on all application servers.

---

<br>
<br>

# Understanding the Requirement

**The security team requested the following change:**

* Prevent users from logging in via SSH using the **root** account.
* Apply this configuration across all application servers.

The root account is the most powerful account in Linux. It has unrestricted access to the entire system, meaning it can modify any file, install software, change system configuration, or delete critical data.

Allowing direct root login increases risk because attackers only need to guess one username: `root`.

By disabling root login, the attack surface is reduced.

---

<br>
<br>

# How SSH Login Works Internally

When a user connects to a server using SSH, several steps occur internally.

1. The SSH client sends a connection request to the SSH server.
2. The SSH daemon (`sshd`) running on the server receives the request.
3. The daemon checks the configuration rules defined in `/etc/ssh/sshd_config`.
4. If the configuration allows the login attempt, authentication begins.
5. If authentication succeeds, the user is granted a shell session.

Because of this design, controlling SSH access is mostly done through the **sshd configuration file**.

---

<br>
<br>

# Step 1 — Editing the SSH Configuration

**The configuration for the SSH server is stored in the file:**

```bash
/etc/ssh/sshd_config
```

This file controls how the SSH daemon behaves.

**To edit it, the following command is used:**

```bash
sudo vi /etc/ssh/sshd_config
```

**Explanation of the command:**

- `sudo` — allows editing the file with root privileges.

- `vi` — a terminal-based text editor commonly available on Linux systems.

- `/etc/ssh/sshd_config` — the configuration file used by the SSH daemon.

**Inside this file, locate the directive:**

```bash
PermitRootLogin
```

**Often this line appears commented out like this:**

```bash
# PermitRootLogin yes
```

The `#` symbol means the line is commented, so the default setting applies.

To disable root login, change the line to:

```bash
PermitRootLogin no
```

This tells the SSH daemon to completely block login attempts using the root account.

---
<b
r>
r>

# Step 2 — Restarting the SSH Service

After modifying configuration files, services must be restarted for the changes to take effect.

**The command used is:**

```bash
sudo systemctl restart sshd
```

**Explanation of the command:**

- `systemctl` is the command-line interface used to manage services in modern Linux systems that use **systemd**.

- `restart` stops the service and starts it again.

- `sshd` refers to the SSH daemon process.

Restarting ensures that the SSH daemon reloads the updated configuration.

---

<br>
<br>

# Understanding the SSH Daemon

The SSH server process is called **sshd**.

The letter `d` stands for **daemon**.

A daemon is a background process that runs continuously and waits for incoming requests. Many Linux services operate as daemons.

**Examples include:**

* `sshd` → SSH server
* `httpd` → Apache web server
* `dockerd` → Docker engine

These services run in the background and are usually managed through the `systemctl` command.

---

<br>
<br>

# Why Disabling Root SSH Login Is Important

- **Protection Against Brute Force Attacks**: Automated bots frequently attempt to log in using the username `root`. If root login is disabled, attackers cannot directly target the most privileged account.

- **Accountability and Auditing:** When administrators log in with personal accounts and use `sudo`, every privileged command is recorded in system logs.

This provides clear audit trails showing who performed each action.

**Example log entry:**

```bash
prashant : TTY=pts/0 ; PWD=/home/prashant ; USER=root ; COMMAND=/usr/bin/systemctl restart nginx

# To get the full log entry, you can check the sudo logs:
sudo cat /var/log/auth.log | grep sudo | grep prashant # on ubuntu/debian

# OR 
sudo cat /var/log/secure | grep sudo | grep prashant # on RHEL/CentOS

# On RHEL/CentOS, to check which user switched to which user and which command executed, you can check the following log:
sudo cat /var/log/secure | grep prashant | grep 'session opened for user root'

```


- **Reduced Risk of Accidental Damage**: Working directly as root increases the risk of accidental system damage.

**A mistyped command such as:**

```bash
rm -rf /
```

could destroy the entire filesystem.

Using `sudo` forces administrators to intentionally elevate privileges only when necessary.

---

<br>
<br>

# Understanding the PermitRootLogin Directive

The `PermitRootLogin` directive controls whether the root user can log in through SSH.

Different values provide different levels of security.

- **`yes`**

```bash
PermitRootLogin yes
```

Root can log in directly using password authentication.

This is the least secure configuration.

---

- **`no`**

```bash
PermitRootLogin no
```

Root login through SSH is completely blocked.

This is the safest configuration and commonly recommended in production environments.

---


- **`prohibit-password`**

```bash
PermitRootLogin prohibit-password
```

Root login is allowed only through **SSH keys**, not passwords.

This configuration is safer than allowing password authentication but still allows automated systems to log in as root if needed.

---

<br>
<br>

# Additional Useful Commands

**Check the SSH service status:**

```bash
systemctl status sshd
```

**Reload SSH configuration without restarting:**

```bash
sudo systemctl reload sshd
```

**Test SSH configuration for syntax errors:**

```bash
sshd -t
```

**View SSH logs:**

```bash
journalctl -u sshd

# journalctl -u sshd -f # to follow logs in real-time

# here journalctl command is used to view logs from the systemd journal, and the -u option filters logs for the sshd service. The -f option allows you to follow the log output in real-time, similar to tail -f.
```

---

<br>
<br>

# Practical Outcome

After applying the configuration change:

* Direct SSH login as root is disabled
* Administrators must log in using personal accounts
* Privileged actions must be performed through `sudo`

This configuration is one of the most basic but essential security hardening steps performed on Linux servers.
