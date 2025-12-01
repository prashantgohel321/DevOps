# Linux Lab 16: Systemd Services

This lab is a deep dive into managing services with `systemd`, the init system used by most modern Linux distributions. You will learn how to troubleshoot failed services, edit unit files, reload the systemd daemon, and configure automatic restarts.

[Image of systemd service lifecycle diagram]

## Table of Contents
- [Linux Lab 16: Systemd Services](#linux-lab-16-systemd-services)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. Checking Service Status](#1-checking-service-status)
      - [2. Attempting to Start a Broken Service](#2-attempting-to-start-a-broken-service)
      - [3. Diagnosing the Failure (journalctl)](#3-diagnosing-the-failure-journalctl)
      - [4. Fixing the Service Unit File](#4-fixing-the-service-unit-file)
      - [5. Verifying the Fix](#5-verifying-the-fix)
      - [6. Enabling the Service](#6-enabling-the-service)
      - [7. Configuring Auto-Restart](#7-configuring-auto-restart)
      - [8. Reloading the Daemon](#8-reloading-the-daemon)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **Systemd:** The system and service manager for Linux. It is the first process started by the kernel (PID 1).
* **Unit File:** A configuration file (usually ending in `.service`) that tells systemd how to manage a specific service. It defines what command to run, when to restart, and dependencies.
* **`systemctl`:** The main command-line tool for controlling systemd.
* **`journalctl`:** The command for viewing logs collected by systemd.
* **Daemon Reload:** When you change a unit file on disk, systemd doesn't know about it automatically. You must run `systemctl daemon-reload` to tell it to re-read the configuration.

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. Checking Service Status
<a name="1-checking-service-status"></a>
**Question:** What is the status of `sample.service`?
**Command:** `sudo systemctl status sample.service`
**Output:** `Loaded: error (Reason: Invalid argument)`, `Active: inactive (dead)`
**Answer:** `inactive`

**Explanation:** The service is not running. The "Loaded: error" indicates a problem with the configuration file itself.

#### 2. Attempting to Start a Broken Service
<a name="2-attempting-to-start-a-broken-service"></a>
**Task:** Try starting the service.
**Command:** `sudo systemctl start sample.service`
**Result:** Failed.

**Explanation:** Systemd cannot start a service with a broken or incomplete configuration file.

#### 3. Diagnosing the Failure (journalctl)
<a name="3-diagnosing-the-failure-journalctl"></a>
**Question:** Why did the service start fail?
**Command:** `sudo journalctl -u sample.service`
**Output:** `Service lacks both ExecStart= and ExecStop=`
**Answer:** `Service Section Not Defined` (specifically, the `ExecStart` directive is missing).

**Explanation:**
* `journalctl -u [unit]`: Shows logs specifically for that unit.
* The error message is explicit: a service *must* know what command to run to start (`ExecStart`).

#### 4. Fixing the Service Unit File
<a name="4-fixing-the-service-unit-file"></a>
**Task:** Update the `[Service]` section to run `/bin/bash /root/sample_script.sh`.
**Command:** `sudo vi /etc/systemd/system/sample.service`

**Edit:**
Add the `ExecStart` line under `[Service]`.
```ini
[Service]
ExecStart=/bin/bash /root/sample_script.sh
```
Save and exit (`:wq`).

#### 5. Verifying the Fix
<a name="5-verifying-the-fix"></a>
**Task:** Start the service and check the status.
**Commands:**
1.  `sudo systemctl start sample.service`
2.  `sudo systemctl status sample.service`

**Output:** `Active: active (running)`
**Answer:** `running`

#### 6. Enabling the Service
<a name="6-enabling-the-service"></a>
**Task:** Configure the service to start automatically on boot.
**Command:** `sudo systemctl enable sample.service`

**Explanation:**
* **Start:** Runs the service *now*.
* **Enable:** Configures the service to start *at boot time*. It usually creates a symbolic link in `/etc/systemd/system/multi-user.target.wants/`.

#### 7. Configuring Auto-Restart
<a name="7-configuring-auto-restart"></a>
**Task:** Ensure the service restarts automatically if it stops.
**Command:** `sudo vi /etc/systemd/system/sample.service`

**Edit:**
Add `Restart=always` to the `[Service]` section.
```ini
[Service]
ExecStart=/bin/bash /root/sample_script.sh
Restart=always
```
Save and exit.

**Why?** This makes the service robust. If the script crashes or is killed, systemd will automatically try to start it again.

#### 8. Reloading the Daemon
<a name="8-reloading-the-daemon"></a>
**Problem:** After editing the file, `systemctl restart` gives a warning: `Warning: The unit file... changed on disk. Run 'systemctl daemon-reload'`.
**Task:** Fix the warning.
**Command:** `sudo systemctl daemon-reload`

**Explanation:**
Whenever you modify a unit file in `/etc/systemd/system/`, systemd needs to reload its internal cache to see the changes. Until you run `daemon-reload`, it is still using the *old* version of the file.

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `systemctl status [unit]` | Check status of a service | `systemctl status sshd` |
| `systemctl start [unit]` | Start a service immediately | `sudo systemctl start nginx` |
| `systemctl stop [unit]` | Stop a service immediately | `sudo systemctl stop nginx` |
| `systemctl restart [unit]` | Restart a service | `sudo systemctl restart nginx` |
| `systemctl enable [unit]` | Enable start on boot | `sudo systemctl enable nginx` |
| `systemctl daemon-reload` | Reload unit file changes | `sudo systemctl daemon-reload` |
| `journalctl -u [unit]` | View logs for a specific service | `journalctl -u nginx` |

    