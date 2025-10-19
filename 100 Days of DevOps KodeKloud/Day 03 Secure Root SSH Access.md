<center><h1>Day 3: Disabling Direct Root SSH Login</h1></center>
<br>
On Day 3, my DevOps journey involved a crucial server hardening task, <mark> **disabling root user login via SSH** </mark>, which is a crucial step for securing a new server across all three app servers.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Solution \& Command Breakdown](#my-solution--command-breakdown)
    - [1. Editing the SSH Configuration File](#1-editing-the-ssh-configuration-file)
    - [2. Restarting the SSH Service](#2-restarting-the-ssh-service)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: The `PermitRootLogin` Directive](#deep-dive-the-permitrootlogin-directive)
  - [Exploring the Files and Commands](#exploring-the-files-and-commands)

---

### The Task
<a name="the-task"></a>
- Following a security audit, I was tasked with disabling direct SSH root login on all app servers in Datacenter. The goal was to prevent anyone from connecting to the servers using the username `root`.

---

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
- I had to repeat the same process on each of the three servers. The process involved editing a single configuration file and then restarting the SSH service.

#### 1. Editing the SSH Configuration File
- First, I connected to each server via SSH using my personal user account. Then, I used a text editor (`vi`) with `sudo` to modify the main SSH daemon configuration file.

```bash
sudo vi /etc/ssh/sshd_config
```

**Command Breakdown:**
* `vi`: The text editor I used to make the change.
* `/etc/ssh/sshd_config`: Configuration file for the SSH *server* (the `d` in `sshd` stands for daemon, which is a background service).

Inside this file, I searched for the line containing `PermitRootLogin`. I found it commented out and set to `yes`: `#PermitRootLogin yes`. I removed the `#` and changed `yes` to `no`. The final line looked like this:

```
PermitRootLogin no
```

#### 2. Restarting the SSH Service
Configuration changes to a service are not applied until the service is restarted. I used `systemctl` to do this.

```bash
sudo systemctl restart sshd
```

**Command Breakdown:**
* `systemctl`: Command-Line-Tool for managing services (daemons) in modern Linux distributions.
* `restart`: The action I wanted `systemctl` to perform.
* `sshd`: The name of the SSH service I wanted to restart.

After completing these two steps on `stapp01`, I exited and repeated the exact same process on `stapp02` and `stapp03`.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
Turning off direct root login is one of the most basic but powerful security steps in Linux. Here’s why:

- **Stops Brute-Force Attacks** → The username root is public knowledge, so hackers and bots constantly try to guess its password. By disabling root login, I remove that target completely — now an attacker must first guess a valid username and the password.

- **Adds Accountability** → Instead of everyone using the same root account, each admin logs in with their own user and uses `sudo` for admin actions. Every `sudo` command is recorded, showing who did what and when, making tracking and auditing easy.

- **Encourages Safety** → Working as a normal user helps prevent accidental damage. You have to type `sudo` to gain admin rights, which forces you to stop and think before running risky commands.

---

### Deep Dive: The `PermitRootLogin` Directive
<a name="deep-dive-the-permitrootlogin-directive"></a>
The `PermitRootLogin` setting in the sshd_config file decides if the root user can log in via SSH. Key options:

- **`yes`** → Allows root to log in directly using a password (often default, but risky).

- **`no`** → Blocks root login completely. This is the safest and what I used.

- **`prohibit-password`** (or without-password) → Root can log in only with SSH keys, not a password. Safer than yes, but not as strict as no.

For security, `no` is the best choice.

---

### Exploring the Files and Commands
<a name="exploring-the-files-and-commands"></a>

* `/etc/ssh/sshd_config`: This is the main configuration file for the SSH server. It controls everything: the SSH port, authentication methods, and user-specific rules. It’s a key file for securing the server.
* `systemctl`: The modern tool **to manage system services** (daemons). I used it to `restart` SSH, but it can also `start`, `stop`, `reload`, `enable` (start on boot), `disable` (don’t start on boot), and check the `status` of services. 