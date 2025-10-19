# Linux Level 1, Task 16: Configuring the `firewalld` Firewall

Today's task was a fundamental exercise in Linux network security: configuring the server's firewall. My objective was to open a specific port to allow access to a web application, a common requirement for any network-facing service.

I learned how to use the `firewall-cmd` utility to interact with the `firewalld` service. The most important lesson was understanding the difference between temporary ("runtime") rules and permanent rules, and the necessity of reloading the firewall to apply permanent changes. This document is my first-person guide to that process.

### The Task

My objective was to open a port on the **Nautilus Backup Server**. The specific requirements were:
-   Allow all incoming TCP traffic on port `6200`.
-   The rule must be applied to the `public` zone.
-   The rule must be permanent (i.e., it must survive a reboot).

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into the backup server (`ssh clint@stbkp01`).

2.  **Add the Permanent Rule:** This was the main command for the task. I used `firewall-cmd` with the `--permanent` flag to ensure the rule would be saved.
    ```bash
    sudo firewall-cmd --permanent --zone=public --add-port=6200/tcp
    ```
    This command returned `success`, indicating the rule was saved to the configuration file.

3.  **Reload the Firewall:** This was a critical step. A permanent rule is not active until the firewall is reloaded.
    ```bash
    sudo firewall-cmd --reload
    ```
    This also returned `success`.

4.  **Verification:** The crucial final step was to confirm that the new rule was active in the running configuration.
    ```bash
    sudo firewall-cmd --list-ports --zone=public
    ```
    The output included `6200/tcp`, which was the definitive proof that my task was successful.

### Key Concepts (The "What & Why")

-   **Firewall**: A firewall is a network security system that acts as a barrier between your server and the outside world. By default, it follows a "deny-all" policy for incoming connections. This means if a service is running on a port, no one can connect to it unless I explicitly create a rule to allow that traffic.
-   **`firewalld`**: This is the modern, dynamic firewall manager for many Linux distributions (like CentOS/RHEL). It's designed to be easier to manage than the older `iptables` service. `firewall-cmd` is the command-line tool I used to interact with it.
-   **Zones**: `firewalld` uses "zones" to manage trust levels. A zone is a collection of rules. The `public` zone is the default for network interfaces and is used for public, untrusted networks. When I added my rule to this zone, I was saying, "For any traffic coming from the public internet, if it's for port 6200, let it through."
-   **Permanent vs. Runtime Rules**: This is a key concept in `firewalld`.
    -   **Runtime (Default):** If I had run the command without `--permanent`, the rule would have been applied *immediately* but would have been lost when the server rebooted or the firewall service was restarted.
    -   **Permanent:** The `--permanent` flag saves the rule to a configuration file. However, it does **not** make the rule active in the current session. I **must** run `sudo firewall-cmd --reload` to load the saved permanent rules into the active runtime configuration.

### Commands I Used

-   `sudo firewall-cmd --permanent --zone=public --add-port=6200/tcp`: The main command for this task.
    -   `firewall-cmd`: The command-line interface for `firewalld`.
    -   `--permanent`: Makes the rule persistent across reboots.
    -   `--zone=public`: Applies the rule to the `public` zone.
    -   `--add-port=6200/tcp`: The action to perform: add a rule to allow traffic on TCP port `6200`.
-   `sudo firewall-cmd --reload`: A critical command that loads the permanent configuration into the active runtime, making the new rules take effect.
-   `sudo firewall-cmd --list-ports --zone=public`: My verification command. It lists all the ports that are currently open in the `public` zone's active configuration.
   