# DevOps Day 6: Automation with Cron Jobs

Today, I took my first steps into true automation by learning about and implementing cron jobs. The task was to set up a scheduled task that would run automatically on all application servers. This is the foundation for automating routine tasks like backups, system checks, or report generation.

It was a great exercise because it wasn't just about one command; it involved installing a service, ensuring it was running, and then configuring the scheduled job itself. Repeating this across multiple servers also drove home the need for future automation tools like Ansible to handle such repetitive tasks at scale.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: Decoding the Cron Schedule](#deep-dive-decoding-the-cron-schedule)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to set up a simple cron job on all three Nautilus app servers (`stapp01`, `stapp02`, `stapp03`). The requirements were:
1.  Install the `cronie` package on all app servers.
2.  Start and enable the `crond` service.
3.  For the `root` user on each server, add a cron job that runs every 5 minutes and executes the command `echo hello > /tmp/cron_text`.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
I performed the following sequence of actions on **each of the three app servers**.

#### Step 1: Install and Start the Cron Service
First, I needed to ensure the cron daemon was installed and running.
```bash
# Install the necessary package
sudo yum install -y cronie

# Start the service for the current session
sudo systemctl start crond

# Enable the service so it starts automatically on reboot
sudo systemctl enable crond
```

#### Step 2: Add the Cron Job for the `root` User
To edit the crontab for a specific user, you use `crontab -e`. To edit it for the `root` user, I had to use `sudo`.
```bash
sudo crontab -e
```
This opened a text editor (vi). I pressed `i` to enter insert mode and added the required line:
```
*/5 * * * * echo hello > /tmp/cron_text
```
Then I pressed `Esc`, and typed `:wq` to save and quit.

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
-   **`cron`**: This is the classic, time-tested utility for scheduling commands on Linux. The service that runs in the background is called the **cron daemon (`crond`)**.
-   **`cronie`**: This is the specific software package on modern Red Hat-based systems (like CentOS) that provides the `crond` service and the `crontab` command.
-   **`crontab`**: This stands for "cron table." It's a special file that contains the list of scheduled jobs. Each user can have their own crontab. Using the `crontab -e` command is the correct and safe way to edit this file, as it checks for syntax errors before saving.
-   **Running as `root`**: Many system administration tasks (like backups or updates) need to be run with elevated privileges. By using `sudo crontab -e`, I was editing the crontab for the system's most powerful user.

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
