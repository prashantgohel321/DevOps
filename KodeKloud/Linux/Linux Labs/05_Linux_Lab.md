# Linux Lab 5: Linux Kernel, Boot & Filetypes

This lab dives into the core components of the Linux operating system. We will explore how the system starts (the boot process), how services are managed (`systemd`), how to identify different types of files, and where important system files are located.

## Table of Contents
- [Linux Lab 5: Linux Kernel, Boot \& Filetypes](#linux-lab-5-linux-kernel-boot--filetypes)
  - [Table of Contents](#table-of-contents)
    - [Key Concepts](#key-concepts)
    - [Step-by-Step Walkthrough](#step-by-step-walkthrough)
      - [1. The Init Process (systemd)](#1-the-init-process-systemd)
      - [2. Systemd Targets (Runlevels)](#2-systemd-targets-runlevels)
      - [3. Changing the Default Target](#3-changing-the-default-target)
      - [4. Identifying File Types (file command)](#4-identifying-file-types-file-command)
      - [5. System Directory Structure (/opt and /dev)](#5-system-directory-structure-opt-and-dev)
      - [6. Hardware Information (lshw)](#6-hardware-information-lshw)
    - [Command Reference](#command-reference)

---

### Key Concepts
<a name="key-concepts"></a>

* **The Init Process (PID 1):** The very first process started by the kernel during boot. It is responsible for starting all other processes and services on the system. Modern Linux systems use `systemd`.
* **Systemd Targets:** These replace the old concept of "runlevels." A target is a state the system can be in.
    * **`multi-user.target`**: The standard non-graphical server mode (like Runlevel 3).
    * **`graphical.target`**: The mode with a GUI desktop (like Runlevel 5).
* **`file` Command:** Linux doesn't rely on file extensions (like `.exe` or `.txt`) to know what a file is. The `file` command looks at the file's *content* (its "magic number") to determine its true type.
* **Filesystem Hierarchy Standard (FHS):** The standard that defines the directory structure of Linux systems (e.g., `/dev` for devices, `/opt` for optional software).

---

### Step-by-Step Walkthrough
<a name="step-by-step-walkthrough"></a>

#### 1. The Init Process (systemd)
<a name="1-the-init-process-systemd"></a>
**Question:** What is the init process used by this system?
**Answer:** `systemd`

**Explanation:**
We checked this by looking at `/sbin/init`.
```bash
sudo ls -l /sbin/init
# Output: ... /sbin/init -> /lib/systemd/systemd
```
This output shows that `/sbin/init` is a **symbolic link** pointing to `/lib/systemd/systemd`. This confirms that `systemd` is the program managing the boot process.

#### 2. Systemd Targets (Runlevels)
<a name="2-systemd-targets-runlevels"></a>
**Question:** What is the default systemd target set in this system?
**Answer:** `graphical.target`

**Explanation:**
We used the `systemctl` command to query the current configuration:
```bash
sudo systemctl get-default
# Output: graphical.target
```
This means that if you rebooted the machine right now, it would try to start a graphical user interface (GUI).

#### 3. Changing the Default Target
<a name="3-changing-the-default-target"></a>
**Task:** Change the target to `multi-user.target`.
**Command:**
```bash
sudo systemctl set-default multi-user.target
```
**Why do this?** Servers usually don't need a GUI. Running a GUI takes up valuable RAM and CPU. Setting the default to `multi-user.target` ensures the server boots into a lightweight, command-line-only mode, which is best practice for servers.

#### 4. Identifying File Types (file command)
<a name="4-identifying-file-types-file-command"></a>
**Question:** What type of file is `firefox.deb`?
**Answer:** `Debian binary package`
**Command:** `sudo file /root/firefox.deb`

**Question:** What type of file is `sample_script.sh`?
**Answer:** `Bourne-Again shell script`
**Command:** `sudo file /root/sample_script.sh`

**Explanation:**
The `file` command reads the header (the first few bytes) of the file to identify it.
* It correctly identified `.deb` as a software package for Debian/Ubuntu systems.
* It correctly identified `.sh` as a shell script (specifically a `bash` script, or "Bourne-Again shell").

#### 5. System Directory Structure (/opt and /dev)
<a name="5-system-directory-structure-opt-and-dev"></a>
**Question:** Where should you install a new third-party IDE?
**Answer:** `/opt`

**Explanation:**
* **`/opt` (Optional):** This is the standard directory for installing add-on application software packages that are not part of the core operating system distribution (like Chrome, Slack, or a custom IDE).
* `/usr/bin`: For package-manager installed software.
* `/bin`: For essential system binaries.

**Question:** Which directory contains files related to block devices (from `lsblk`)?
**Answer:** `/dev`

**Explanation:**
* **`/dev` (Devices):** In Linux, "everything is a file." Hardware devices like hard drives (`sda`, `nvme0n1`), partitions, terminals, and USB inputs are represented as special files in this directory.

#### 6. Hardware Information (lshw)
<a name="6-hardware-information-lshw"></a>
**Question:** What is the vendor of the Ethernet Controller?
**Answer:** `Red Hat, Inc.`

**Explanation:**
We used the `lshw` (List Hardware) command.
```bash
sudo lshw -class network
```
This filters the output to show only network devices. The output showed:
```
*-network
     description: Ethernet controller
     vendor: Red Hat, Inc.   <-- The Answer
     product: Virtio network device
```
This tells us the system is likely a Virtual Machine (VM) using the "Virtio" driver provided by Red Hat's virtualization technology.

---

### Command Reference
<a name="command-reference"></a>

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `ls -l` | List files in long format (shows symlinks) | `ls -l /sbin/init` |
| `systemctl get-default` | Show the current default boot target | `systemctl get-default` |
| `systemctl set-default` | Change the default boot target | `sudo systemctl set-default multi-user.target` |
| `file` | Determine file type | `file myfile.tar.gz` |
| `lshw` | List Hardware | `sudo lshw -class network` |
| `lsblk` | List Block Devices | `lsblk` |

   