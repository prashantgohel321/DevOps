<center><h1>DevOps Day 5<br>Installing SELinux and Handling Unexpected Issues</h1></center>
<br>

On Day 5, a server was prepared for a new security implementation using SELinux, requiring installation of necessary tools and disabling SELinux in its configuration file.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [The Final Solution](#the-final-solution)
    - [1. Install the Correct Packages](#1-install-the-correct-packages)
    - [2. Configure SELinux to be Disabled](#2-configure-selinux-to-be-disabled)
  - [My Troubleshooting Journey](#my-troubleshooting-journey)
    - [Hurdle #1: "Packages Not Installed" Error](#hurdle-1-packages-not-installed-error)
    - [Hurdle #2: Empty Configuration File](#hurdle-2-empty-configuration-file)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: The `/etc/selinux/config` File](#deep-dive-the-etcselinuxconfig-file)
  - [Key Takeaways from This Task](#key-takeaways-from-this-task)

---

### The Task
<a name="the-task"></a>
- The task involved installing `SELinux` packages, permanently disabling SELinux by modifying its configuration file, and ensuring the change only takes effect after the next reboot.

---

### The Final Solution
<a name="the-final-solution"></a>

#### 1. Install the Correct Packages
- The key was to identify the exact package names for this version of Linux.

```bash
sudo yum install policycoreutils selinux-policy -y
```

**Command Breakdown:**
* `sudo yum install -y`: Command to install software with admin rights and auto-confirm prompts.
* `policycoreutils`: Provides essential tools to manage SELinux, like `sestatus` and `setenforce`.
* `selinux-policy`: Contains the rules (policy) that SELinux enforces. This package is required for SELinux to work.

#### 2. Configure SELinux to be Disabled
Next, I edited the configuration file to disable SELinux on the next boot.

```bash
sudo vi /etc/selinux/config

# Inside the file, I changed the `SELINUX` directive to `disabled`:
# SELINUX=disabled
```

---

### My Troubleshooting Journey
<a name="my-troubleshooting-journey"></a>
I faced two main problems while setting up SELinux:

#### Hurdle #1: "Packages Not Installed" Error
- I first tried `sudo yum install -y policycoreutils-python`, which failed: “Unable to find a match.”
- **Lesson**: Package names differ across Linux versions. The `-python` version exists in older systems (like CentOS 7), but in newer systems, the tools are bundled differently. I also needed `selinux-policy` for the validation script.

#### Hurdle #2: Empty Configuration File
- I found `/etc/selinux/config` was empty. An empty file makes the system default to enforcing mode, causing task failure.
- **Solution**: I created the file from scratch using a here document:

```bash
sudo bash -c 'cat > /etc/selinux/config <<EOF
# This file controls the state of SELinux on the system.
SELINUX=disabled
SELINUXTYPE=targeted
EOF'
```
This writes everything between `EOF` markers into the file in one go — fast, reliable, and non-interactive.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
This task simulates a very common real-world scenario.

-   **What is SELinux?** It’s a security layer beyond regular user/group permissions. It controls exactly what programs can do. For example, it can stop Apache from accessing users’ home files, even if normal permissions allow it.
-   **Why Install It?** To use SELinux, you need the tools (`policycoreutils`) to manage it and the rules (`selinux-policy`) to enforce actions.
-   **Why Disable It (Temporarily)?** SELinux is powerful but tricky. Admins often disable it while installing new apps or troubleshooting, so things work first. Later, they can re-enable it with proper policies without breaking the system.

---

### Deep Dive: The `/etc/selinux/config` File
<a name="deep-dive-the-etcselinuxconfig-file"></a>
This file controls SELinux at boot. The key setting is `SELINUX=`, which can be:

-   `enforcing`: Default and most secure. SELinux blocks any action that breaks its rules.
-   `permissive`: SELinux is active but only logs warnings instead of blocking actions. Good for testing policies.
-   `disabled`: SELinux is fully off. No policies are loaded. This is what I set it to.

---

### Key Takeaways from This Task
<a name="key-takeaways-from-this-task"></a>
- Run **`cat /etc/os-release`** to check the linux distribution name
