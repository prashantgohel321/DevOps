# Day 3: Disabling Direct Root SSH Login

Day 3 of my DevOps journey involved a fundamental server hardening task: disabling the root user's ability to log in directly via SSH. This is one of the first things a system administrator does to secure a new server. My mission was to apply this security protocol across all three app servers.

This task drove home the importance of layered security and creating an audit trail for all administrative actions.

<img src="SS/Day03.png">

## Table of Contents
- [The Task](#the-task)
- [My Solution & Command Breakdown](#my-solution--command-breakdown)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The `PermitRootLogin` Directive](#deep-dive-the-permitrootlogin-directive)
- [Exploring the Files and Commands](#exploring-the-files-and-commands)

---

### The Task
<a name="the-task"></a>
Following a security audit, I was tasked with disabling direct SSH root login on all app servers (`stapp01`, `stapp02`, `stapp03`) in the Stratos Datacenter. The goal was to prevent anyone from connecting to the servers using the username `root`.

---

### My Solution & Command Breakdown
<a name="my-solution--command-breakdown"></a>
I had to repeat the same process on each of the three servers. The process involved editing a single configuration file and then restarting the SSH service.

#### 1. Editing the SSH Configuration File
First, I connected to each server via SSH using my personal user account. Then, I used a text editor (`vi`) with `sudo` to modify the main SSH daemon configuration file.

```bash
sudo vi /etc/ssh/sshd_config
```

**Command Breakdown:**
* `sudo`: Required to edit a system-level configuration file owned by the root user.
* `vi`: The text editor I used to make the change.
* `/etc/ssh/sshd_config`: This is the full path to the configuration file for the SSH *server* (the `d` in `sshd` stands for daemon, which is a background service).

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
* `sudo`: Restarting a system service is an administrative action.
* `systemctl`: The primary tool for managing services (daemons) in modern Linux distributions.
* `restart`: The action I wanted `systemctl` to perform.
* `sshd`: The name of the SSH service I wanted to restart.

After completing these two steps on `stapp01`, I exited and repeated the exact same process on `stapp02` and `stapp03`.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
Disabling direct root login is a non-negotiable, first-line-of-defense security measure. The reasons are simple but powerful:

-   **Reduces Brute-Force Attack Surface**: The username `root` is a known target on every Linux system. Automated bots constantly scan the internet for servers and try to guess the `root` password. By disabling root login, I made that entire class of attacks useless. The attacker would now need to guess both a valid username *and* a password.
-   **Enforces Accountability and Auditing**: This is the most important reason from a DevOps and operational perspective. It forces all administrators to log in with their own, unique user accounts. To perform a privileged action, they must then use `sudo`. Every command run with `sudo` is logged in the system's logs, creating a clear audit trail. We can see *who* ran *what command* and *when*. If everyone just logs in as `root`, accountability is lost.
-   **Promotes Caution**: It encourages a safer workflow. By logging in as a non-privileged user, I'm less likely to accidentally run a destructive command. I have to consciously type `sudo` to elevate my privileges, which provides a moment to pause and think about the command I'm about to execute.

---

### Deep Dive: The `PermitRootLogin` Directive
<a name="deep-dive-the-permitrootlogin-directive"></a>
The `PermitRootLogin` directive in the `sshd_config` file controls whether the `root` user can log in using SSH. It has a few possible values, but the main ones are:

-   `yes`: This is often the default. It allows the root user to log in directly by providing the root password.
-   `no`: This is what I set it to. It completely blocks the root user from authenticating via SSH. This is the recommended security practice.
-   `prohibit-password` (or `without-password`): This is a middle ground. It allows root to log in, but *only* using public key authentication, not with a password. This is much more secure than `yes` but less secure than `no`.

For this task, setting it to `no` was the correct and most secure choice.

---

### Exploring the Files and Commands
<a name="exploring-the-files-and-commands"></a>
This task centered on two key components of a Linux system.

* `/etc/ssh/sshd_config`: I now understand this is the master configuration file for the SSH *server*. It controls everything from which port SSH listens on, to what kind of authentication is allowed, to user-specific rules. It's a critical file for securing a server.
* `systemctl`: This is the modern command for managing system services (daemons). I used `restart`, but I can also use it to `start`, `stop`, `reload`, `enable` (start on boot), `disable` (don't start on boot), and check the `status` of any service. It's an essential tool for any system administrator.
