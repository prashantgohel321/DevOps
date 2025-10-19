# Linux Level 1, Task 18: Permanently Disabling SELinux

Today's task was a common system administration duty related to server security and configuration. My goal was to permanently disable SELinux on an app server. This is often a prerequisite step during initial server setup or when troubleshooting complex application compatibility issues.

The most important part of this task was understanding the difference between a temporary, runtime change and a permanent configuration change that only takes effect on the next reboot. This document is my first-person guide to that process.

### The Task

My objective was to configure SELinux on **App Server 3**. The specific requirements were:
-   Install the required SELinux packages.
-   **Permanently** disable SELinux so that the change takes effect on the next reboot.
-   Do **not** reboot the server.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 3 (`ssh banner@stapp03`).

2.  **Install Packages:** I ensured the necessary SELinux management tools were installed.
    ```bash
    sudo yum install -y policycoreutils selinux-policy
    ```

3.  **Edit the Configuration File:** This was the core of the task. I edited the `/etc/selinux/config` file to make a permanent change.
    ```bash
    sudo vi /etc/selinux/config
    ```
    Inside the editor, I found the line `SELINUX=enforcing` and changed it to:
    ```
    SELINUX=disabled
    ```

4.  **Verification:** The verification for this task was nuanced. The task was to change the *boot* configuration, not the *running* configuration.
    -   First, I checked the current running state, which was unchanged as expected.
        ```bash
        getenforce
        # Output: Enforcing
        ```
    -   Then, I performed the real verification by checking the contents of the file I had just edited. This is the definitive proof of success for this task.
        ```bash
        grep SELINUX=disabled /etc/selinux/config
        # Output: SELINUX=disabled
        ```
    This confirmed that on the next reboot, the server would start with SELinux disabled.

### Key Concepts (The "What & Why")

-   **SELinux (Security-Enhanced Linux)**: SELinux is a powerful and complex security module for the Linux kernel. It provides a mechanism for supporting access control security policies, applying what's known as Mandatory Access Control (MAC). It goes far beyond the standard user/group/other file permissions to control how processes can interact with each other and the filesystem.
-   **Why Disable It?**: While extremely powerful for security, SELinux can be complex to configure. Sysadmins often temporarily disable it during initial software installation or when debugging an application to rule out SELinux as the cause of a problem, with the plan to re-enable it later with a correct, tailored policy.
-   **Permanent vs. Runtime Configuration**: This was the key lesson.
    -   **Runtime (`setenforce`)**: The `setenforce 0` command can switch SELinux to "Permissive" mode *immediately*, but this change is temporary and will be reset on the next reboot.
    -   **Permanent (`/etc/selinux/config`)**: This is the master configuration file that the system reads during the boot process to determine what state SELinux should be in. Editing this file is the only way to make a change that persists across reboots. My task was specifically to make a permanent change.

### Commands I Used

-   `sudo yum install -y policycoreutils selinux-policy`: Installs the core packages needed to manage SELinux policies and settings.
-   `sudo vi /etc/selinux/config`: The command to edit the main SELinux configuration file, which controls its boot-time state.
-   `getenforce`: A simple command to check the *current, running mode* of SELinux (either `Enforcing`, `Permissive`, or `Disabled`).
-   `grep SELINUX=disabled /etc/selinux/config`: My primary verification command. It searches for and prints the line containing `SELINUX=disabled` from the configuration file, proving that I made the permanent change correctly.
  