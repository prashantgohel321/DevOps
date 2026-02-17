# Linux Level 1, Task 13: Securing `cron` with Access Control Files

Today's task was a practical and important security hardening exercise. My goal was to restrict which users on a server are allowed to create scheduled tasks using `cron`. This is a critical step in locking down a system, as unrestricted `cron` access can be a potential security risk.

I learned about the two special files, `/etc/cron.allow` and `/etc/cron.deny`, and the logic that governs how they control access to the `crontab` command. This document is my first-person guide to that process, explaining the concepts and the commands I used.

### The Task

My objective was to configure `crontab` access on **App Server 2**. The specific requirements were:
-   **Allow** crontab access for the user `ammar`.
-   **Deny** crontab access for the user `ryan`.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into App Server 2 (`ssh steve@stapp02`).

2.  **Create the `cron.allow` File:** The most secure and explicit way to meet the requirements is to use the "whitelist" approach. By creating a `/etc/cron.allow` file, I ensure that *only* the users listed in it have access.
    ```bash
    echo "ammar" | sudo tee /etc/cron.allow
    ```
    This command creates the file and adds `ammar`'s name to it in a single step.

3.  **Create the `cron.deny` File (Good Practice):** While the `cron.allow` file is all that's technically needed to solve the task, explicitly adding `ryan` to `/etc/cron.deny` makes the configuration intent clearer.
    ```bash
    echo "ryan" | sudo tee /etc/cron.deny
    ```

4.  **Verification:** The crucial final step was to test my new security policy. The best way to do this is to attempt an action that should be denied. I tried to list the crontab for the `ryan` user.
    ```bash
    sudo -u ryan crontab -l
    ```
    The command failed with the message `You (ryan) are not allowed to use this program (crontab)`. This failure was the definitive proof that my security configuration was working correctly.

### Key Concepts (The "What & Why")

-   **`cron` and `crontab`**: `cron` is the time-based job scheduler service in Linux. `crontab` is the command users run to edit their personal list of scheduled jobs.
-   **Why Restrict Access?**: On a multi-user system, allowing any user to schedule jobs can be a security risk. A malicious user could schedule a script to consume system resources (a "fork bomb"), scan the network, or try to escalate privileges. For security and compliance, it's a best practice to restrict `crontab` access to only trusted users or service accounts.
-   **The `cron.allow` and `cron.deny` Logic**: The `cron` daemon follows a strict order of precedence to determine access:
    1.  **Check for `/etc/cron.allow`:** If this file exists, the logic is very simple: **only users listed in this file are allowed access.** Everyone else is denied, and the `cron.deny` file is completely ignored. This is a "whitelist" approach and is considered the most secure method.
    2.  **Check for `/etc/cron.deny`:** If `cron.allow` does **not** exist, the daemon then looks for this file. If it exists, any user listed in this file is **denied** access. Everyone else is allowed. This is a "blacklist" approach.
    3.  **If Neither File Exists:** The behavior can vary, but on many systems, only the `root` user is allowed access.

    By creating `cron.allow` with `ammar` in it, I immediately satisfied both requirements of the task.

### Commands I Used

-   `echo "ammar" | sudo tee /etc/cron.allow`: This is a safe and efficient way to create a file owned by `root`.
    -   `echo "ammar"`: Prints the username to standard output.
    -   `|`: The "pipe" operator, which sends the output of the `echo` command as the input to the next command.
    -   `sudo tee /etc/cron.allow`: The `tee` command reads from standard input and writes to both the screen and the specified file. I used `sudo` with `tee` because I, as a regular user, do not have permission to write directly to the `/etc` directory.
-   `sudo -u ryan crontab -l`: My verification command.
    -   `-u ryan`: A flag for the `sudo` command that tells it to run the following command as the **u**ser `ryan`, not as `root`.
    -   `crontab -l`: The command to **l**ist the crontab for the current user. The failure of this command for the `ryan` user was the proof of success.
  