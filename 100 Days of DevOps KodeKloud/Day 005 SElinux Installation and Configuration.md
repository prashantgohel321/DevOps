# DevOps Day 05 — Installing SELinux Tools and Configuring SELinux

<br>
<br>

## Real Scenario

- Modern Linux systems include several layers of security. One of the most powerful security frameworks available on many enterprise Linux distributions such as **RHEL, CentOS, Rocky Linux, and AlmaLinux** is **SELinux (Security-Enhanced Linux)**.

- SELinux adds an additional access control layer on top of traditional Linux permissions. While standard Linux permissions control access using **user, group, and others**, SELinux enforces rules based on **security contexts and policies** that define how programs interact with files, processes, and network resources.

- In this task, the server needed to be prepared for SELinux-based security implementation. This required installing SELinux management tools and modifying the system configuration so SELinux would be disabled on the next system boot.


---

<br>
<br>

# Understanding the Requirement

**The task involved three important steps:**

1. Install the required SELinux management packages.
2. Modify the SELinux configuration file.
3. Ensure the SELinux state becomes **disabled after the next reboot**.

Even though SELinux provides strong security protection, administrators sometimes temporarily disable it while configuring applications or troubleshooting system behavior.

---

<br>
<br>

# What SELinux Actually Is

- SELinux stands for **Security-Enhanced Linux**.

- It implements a security model known as **Mandatory Access Control (MAC)**.

- Traditional Linux permissions follow a model called **Discretionary Access Control (DAC)**, where file owners decide who can access files.

- SELinux adds another layer that even the root user must obey.

**For example:**

- Even if file permissions allow access, SELinux may still block the action if it violates the configured policy.

**Example scenario:**

- An Apache web server process may attempt to read files in `/home/user`.

- Standard permissions might allow it, but SELinux can block this access because the web server is not allowed to read files from that location according to its policy rules.

---

<br>
<br>

# Step 1 — Installing SELinux Packages

To manage SELinux, certain packages must be installed.

**The command used was:**

```bash
sudo yum install policycoreutils selinux-policy -y
```

Explanation of the command:

---

- **`sudo`**

The command begins with `sudo` to execute the package installation with administrative privileges.

Package management modifies system directories such as:

```bash
/usr/bin  # To place executable tools, 
/usr/lib  # To place libraries, 
/etc      # To place configuration files
```

Therefore root privileges are required.

---

- **`yum install`**

- `yum` stands for **Yellowdog Updater Modified**.

- It is the package manager used on older RHEL-based systems such as CentOS 7.

**The command:**

```bash
yum install
```

downloads packages from configured repositories and installs them into the system.

Modern systems often use `dnf`, which is the successor to yum.

---

- **`-y` Option**

- The `-y` option automatically answers **yes** to all prompts.

- Without it, yum would ask for confirmation before installing packages.

---

- **`policycoreutils` Package**

This package provides essential tools used to interact with SELinux.

**Some important utilities included are:**

```bash
sestatus     # Check SELinux status
setenforce   # Change SELinux enforcement mode
restorecon   # Restore file security contexts
semanage     # Manage SELinux policy components
```

These commands allow administrators to check SELinux status, change enforcement modes, and restore security contexts on files.

---

- **`selinux-policy` Package**

- SELinux policies define **what actions are allowed or denied**.

- Without policy files, SELinux cannot enforce security rules.

- This package installs the base policy rules required for SELinux operation.

- This policy files are typically located in:

```bash
/usr/share/selinux/targeted
```

---

<br>
<br>

# Step 2 — Modifying the SELinux Configuration

SELinux configuration at boot time is controlled through the file:

```bash
/etc/selinux/config  # Main configuration file for SELinux
```

To edit the file:

```bash
sudo vi /etc/selinux/config  
```

Inside the file the following directive determines the SELinux state.

```bash
SELINUX=disabled
```

Possible values include:

```bash
SELINUX=enforcing   # Meaning SELinux actively enforces policies and blocks unauthorized actions.
SELINUX=permissive  # Meaning SELinux does not block actions but logs violations for debugging purposes.
SELINUX=disabled    # Meaning SELinux is completely turned off and no policies are loaded.
```

---

**enforcing Mode**
- SELinux actively blocks operations that violate policy rules.
- This is the most secure configuration.

---

**permissive Mode**
- SELinux does not block actions but logs violations.
- This mode is useful for debugging policies.

---

**disabled Mode**
- SELinux is completely turned off.
- No policies are loaded and no security checks occur.

---

<br>
<br>

# Why Changes Apply Only After Reboot

- SELinux state is determined during system startup.
- When the kernel initializes security modules during boot, it loads SELinux policies according to the configuration file.
- Changing the configuration file does not immediately affect the running kernel.
- Therefore a **system reboot** is required for the new state to apply.

---

<br>
<br>

# Troubleshooting Problems During Setup

During the configuration process two issues appeared.

---

**Problem 1 — Package Not Found**

Attempting to install:

```bash
policycoreutils-python
```

- resulted in an error because package names differ between Linux versions.
- Older distributions include `policycoreutils-python`, while newer systems bundle the utilities differently.

**This highlights an important lesson:**

Always verify package availability using commands like:

```bash
yum search policycoreutils
# or
dnf search policycoreutils

# on ubuntu-based systems
apt search policycoreutils
```

---

**Problem 2 — Empty Configuration File**

- The file `/etc/selinux/config` was found empty.
- If this configuration file does not contain proper directives, the system may default to **enforcing mode**, which can cause unexpected behavior.
- To recreate the file, a **here document** was used.

```bash
sudo bash -c 'cat > /etc/selinux/config <<EOF
SELINUX=disabled
SELINUXTYPE=targeted
EOF'
```

---

<br>
<br>

# Understanding Here Documents

A here document allows multiple lines of text to be passed to a command.

In this case:

```bash
cat > file <<EOF
...
EOF
```

means everything between `EOF` markers will be written into the file.

This method is useful for scripting and automation because it avoids interactive editing.

---

<br>
<br>

# Checking SELinux Status

After installation administrators usually verify SELinux state.

```bash
sestatus
```

Example output:

```bash
SELinux status:                 enabled
Current mode:                   enforcing
Mode from config file:          disabled
```

This shows the current runtime state and the configuration that will apply after reboot.

---

<br>
<br>

# Useful Commands for SELinux Management

**Check SELinux status:**

```bash
sestatus
```

**Temporarily change enforcement mode:**

```bash
setenforce 0
```

**Enable enforcement again:**

```bash
setenforce 1
```

**Restore file security contexts:**

```bash
restorecon -Rv /var/www

# Restore security contexts recursively for the web server directory
# restorecon will reset the SELinux context of files to their default values based on the policy rules.
# -R means recursive, and -v means verbose output.
```

---

<br>
<br>

# Why SELinux Is Important in DevOps Environments

- SELinux helps protect systems against application vulnerabilities.
- Even if a web server becomes compromised, SELinux can limit the damage by preventing the process from accessing unauthorized files or services.
- This containment approach is called **least privilege enforcement** at the system level.

---

<br>
<br>

# Practical Outcome

After completing this task:

* SELinux management tools were installed
* SELinux configuration was modified
* The system will boot with SELinux disabled

Understanding SELinux is an important skill for DevOps engineers because it frequently affects application deployment, container security, and production server hardening.
