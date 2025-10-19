<center><h1>DevOps Day 6<br>Automation with Cron Jobs</h1></center>
<br>
Today I learned about automation by implementing `cron` jobs to set up a scheduled task for all application servers. This exercise highlighted the importance of automating routine tasks like backups, system checks, and report generation. The process involved installing a service, ensuring it was running, and configuring the scheduled job.

## Table of Contents
- [Table of Contents](#table-of-contents)
  - [The Task](#the-task)
  - [My Step-by-Step Solution](#my-step-by-step-solution)
    - [Step 1: Install and Start the Cron Service](#step-1-install-and-start-the-cron-service)
    - [Step 2: Add the Cron Job for the `root` User](#step-2-add-the-cron-job-for-the-root-user)
    - [Step 3: Verification](#step-3-verification)
  - [Why Did I Do This? (The "What \& Why")](#why-did-i-do-this-the-what--why)
  - [Deep Dive: Decoding the Cron Schedule](#deep-dive-decoding-the-cron-schedule)
  - [Common Pitfalls](#common-pitfalls)
  - [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
- The goal was to establish a `cron` job on three Nautilus `app servers`, installing the '`cronie`' package, enabling the '`crond`' service, and adding a cron job for the '`root`' user every 5 minutes, executing the command '`echo hello > /tmp/cron_text`'.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
- I performed the following sequence of actions on **each of the three app servers**.

#### Step 1: Install and Start the Cron Service
- First, I needed to ensure the cron daemon was installed and running.
```bash
# Install the necessary package
sudo yum install -y cronie

# Start the service for the current session
sudo systemctl start crond

# Enable the service so it starts automatically on reboot
sudo systemctl enable crond
```

#### Step 2: Add the Cron Job for the `root` User
- To edit the `crontab` for a specific user, I used `crontab -e`. To edit it for the `root` user, I had to use `sudo`.
```bash
sudo crontab -e

# This opened a text editor (vi). I pressed `i` to enter insert mode and added the required line:
*/5 * * * * echo hello > /tmp/cron_text

# Then I pressed `Esc`, and typed `:wq` to save and quit.
```

#### Step 3: Verification
The most important part is making sure the job is scheduled and works correctly.
* **Check the schedule:** I listed the cron jobs for the `root` user to ensure my entry was saved.
    ```bash
    sudo crontab -l
    ```
* **Check the output:** I waited for up to 5 minutes for the job to execute. Then, I checked the output file.
    ```bash
    cat /tmp/cron_text
    ```
    Seeing the word "hello" in this file was the final confirmation of success.

I repeated these three steps on all app servers to complete the task.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>
-   **`cron`**: The classic Linux tool for **scheduling tasks**. The background service that runs it is called `crond`
-   **`cronie`**: The package on modern Red Hat-based systems (like CentOS) that provides `crond` and the `crontab` command.
-   **`crontab`**: Stands for **cron table**. It’s a file listing scheduled jobs. Each user can have their own `crontab`. Editing with `crontab -e` is safe because it checks syntax before saving.
-   **Running as `root`**: Some tasks, like backups or updates, need admin privileges. Using `sudo crontab -e` edits the root user’s crontab, letting these tasks run with full permissions.

---

### Deep Dive: Decoding the Cron Schedule
<a name="deep-dive-decoding-the-cron-schedule"></a>
The `*/5 * * * *` part can look cryptic, but it follows a simple pattern. There are five fields, representing different units of time.

```
.---------------- minute (0 - 59)
|  .------------- hour (0 - 23)
|  |  .---------- day of month (1 - 31)
|  |  |  .------- month (1 - 12)
|  |  |  |  .---- day of week (0 - 6) (Sunday to Saturday)
|  |  |  |  |
* * * * * <-- command to be executed
```
- A * means "every".
- */5 in the minute field means "every 5th minute".

> So, `*/5 * * * *` translates to: "At every 5th minute, of every hour, on every day-of-month, of every month, on every day-of-week."

---

### Common Pitfalls
<a name="common-pitfalls"></a>

**Editing the Wrong Crontab**: If you forget `sudo`, `crontab -e` edits your personal `crontab` (e.g., user tony) instead of root’s. Make sure you use `sudo` for system-level tasks.

**Path Issues**: Cron runs in a minimal environment. Always use **absolute paths for commands** and files (e.g., `/bin/echo` instead of `echo`) to avoid “command not found” errors.

---

### Exploring the Commands Used

<a name="exploring-the-commands-used"></a>
- **`sudo yum install -y cronie`**: Installs the cron service package.
- **`sudo systemctl start crond`**: Starts the cron daemon for the current session.
- **`sudo systemctl enable crond`**: Configures the cron daemon to start automatically when the server boots.
- **`sudo crontab -e`**: Edits the crontab for the root user.
- **`sudo crontab -l`**: Lists the crontab for the root user.
- **`cat /tmp/cron_text`**: Displays the content of the output file to verify the job ran.