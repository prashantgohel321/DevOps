# DevOps Day 06 — Automating Tasks with Cron Jobs 

<br>
<br>

- [DevOps Day 06 — Automating Tasks with Cron Jobs](#devops-day-06--automating-tasks-with-cron-jobs)
  - [Real Scenario](#real-scenario)
- [Understanding the Requirement](#understanding-the-requirement)
- [What Cron Is](#what-cron-is)
- [Step 1 — Installing the Cron Service](#step-1--installing-the-cron-service)
- [Step 2 — Starting the Cron Daemon](#step-2--starting-the-cron-daemon)
- [Step 3 — Enabling Cron at Boot](#step-3--enabling-cron-at-boot)
- [Step 4 — Creating the Scheduled Task](#step-4--creating-the-scheduled-task)
- [The Cron Job Entry](#the-cron-job-entry)
- [Understanding the Cron Time Format](#understanding-the-cron-time-format)
- [Step 5 — Verifying the Cron Job](#step-5--verifying-the-cron-job)
- [Checking the Output of the Job](#checking-the-output-of-the-job)
- [How Cron Works Internally](#how-cron-works-internally)
- [Where Cron Jobs Are Stored](#where-cron-jobs-are-stored)
- [Common Problems with Cron Jobs](#common-problems-with-cron-jobs)
- [Useful Commands for Cron Administration](#useful-commands-for-cron-administration)
- [Practical Outcome](#practical-outcome)


<br>
<br>

## Real Scenario

- In production Linux environments, many tasks must run repeatedly without human intervention. Examples include backups, log rotation, monitoring scripts, database cleanup tasks, certificate renewal, and health checks. Performing these tasks manually would be inefficient and unreliable.

- Linux solves this problem using a scheduling system called **cron**. Cron allows administrators to schedule commands or scripts to run automatically at specific times or intervals.

- In this task, a cron job had to be configured on three application servers so that every five minutes the system would execute a command that writes the word `hello` into the file `/tmp/cron_text`.


---

<br>
<br>

# Understanding the Requirement

**The task required several steps:**

1. Install the cron service package.
2. Ensure the cron daemon is running.
3. Configure a scheduled task using `crontab`.
4. Verify that the job executes correctly.

**The scheduled command was:**

```bash
echo hello > /tmp/cron_text
```

This command overwrites the file `/tmp/cron_text` with the text `hello` every five minutes.

---

<br>
<br>

# What Cron Is

- Cron is a **time-based job scheduler** used in Unix and Linux systems.

- It works through a background process called a **daemon** named `crond`. A daemon is a long-running background service that continuously waits for events or scheduled triggers.

- Cron reads configuration files called **crontabs** (cron tables). Each crontab contains a list of commands and their execution schedules.

- When the system clock matches a schedule defined in the crontab, the cron daemon runs the corresponding command automatically.

---

<br>
<br>

# Step 1 — Installing the Cron Service

Before scheduling jobs, the cron service must be installed.

```bash
sudo yum install -y cronie
```

**Explanation:**

`yum` is the package manager used in many RHEL-based systems such as CentOS and Rocky Linux.

The package **cronie** provides:

* the `crond` daemon
* the `crontab` command
* supporting libraries for job scheduling

The `-y` flag automatically confirms installation prompts.

---

<br>
<br>

# Step 2 — Starting the Cron Daemon

After installation, the cron service must be started.

```bash
sudo systemctl start crond
```

**Explanation:**

- `systemctl` is the command used to manage services in systems that use **systemd**, the modern Linux service manager.
- The command `start` launches the cron daemon for the current session.

---

<br>
<br>

# Step 3 — Enabling Cron at Boot

To ensure cron starts automatically after a server reboot, the service must be enabled.

```bash
sudo systemctl enable crond
```

This creates a symbolic link in systemd's startup configuration so the service launches during system boot.

---

<br>
<br>

# Step 4 — Creating the Scheduled Task

To create a cron job for the root user, the following command is used:

```bash
sudo crontab -e
```

**Explanation:**

- `crontab` is the command used to manage cron job schedules.
- The `-e` option opens the crontab file in the default text editor so new scheduled tasks can be added.
- Using `sudo` edits the **root user's crontab**, which allows scheduled commands to run with administrative privileges.

---

<br>
<br>

# The Cron Job Entry

**Inside the editor the following line was added:**

```bash
*/5 * * * * echo hello > /tmp/cron_text
```

- This line contains **five scheduling fields followed by the command**.
- Cron syntax may initially appear confusing, but each field represents a specific time unit.

---

<br>
<br>

# Understanding the Cron Time Format

**Cron uses five time fields arranged in the following order:**

```bash
* * * * * command
| | | | |
| | | | +---- Day of week (0–6, Sunday=0)
| | | +------ Month (1–12)
| | +-------- Day of month (1–31)
| +---------- Hour (0–23)
+------------ Minute (0–59)
```

**In this task the schedule was:**

```bash
*/5 * * * *
```

**Explanation:**

- `*/5` in the minute field means **every five minutes**.
- The remaining `*` symbols mean **every possible value** for that field.

**So the job runs:**

* every 5 minutes
* every hour
* every day
* every month
* every day of the week

---

<br>
<br>

# Step 5 — Verifying the Cron Job

After saving the crontab file, verification is important.

**To view the scheduled jobs for the root user:**

```bash
sudo crontab -l
```

- The `-l` option lists existing cron jobs.
- If the job appears in the output, the configuration was saved successfully.

---

<br>
<br>

# Checking the Output of the Job

After waiting a few minutes, the output file should contain the scheduled command's result.

```bash
cat /tmp/cron_text
```

**If the job ran successfully, the output should display:**

```bash
hello
```

---

<br>
<br>

# How Cron Works Internally

- The cron daemon wakes up every minute and checks all crontab schedules.

- If the current system time matches any scheduled entry, cron executes the associated command.

- Cron executes commands in a minimal environment, meaning it does not load the full user environment variables normally available in an interactive shell.

- Because of this, scripts used in cron jobs should typically include **absolute paths** for commands.

**Example:**

```bash
/bin/echo hello
```

**instead of simply:**

```bash
echo hello
```

---

<br>
<br>

# Where Cron Jobs Are Stored

**User-specific cron jobs are stored in:**

```bash
/var/spool/cron/
```

Each user has a file with their username containing their scheduled tasks.

**System-wide cron jobs may also be configured in:**

```bash
/etc/crontab
/etc/cron.d/
/etc/cron.daily/
/etc/cron.hourly/
```

These directories allow administrators to schedule tasks globally across the system.

---

<br>
<br>

# Common Problems with Cron Jobs

**Editing the Wrong Crontab**: Running `crontab -e` without `sudo` edits the current user's crontab rather than the root user's.

**Missing Absolute Paths**: Cron may fail to find commands if the PATH environment variable is limited.

**Permissions Issues**: Scripts executed by cron must have proper execution permissions.

---

<br>
<br>

# Useful Commands for Cron Administration

Check cron service status:

```bash
systemctl status crond
```

**View cron logs:**

```bash
journalctl -u crond
```

**Remove all cron jobs for a user:**

```bash
crontab -r
```

**Edit another user's cron jobs:**

```bash
sudo crontab -u username -e
```

---

<br>
<br>

# Practical Outcome

**After completing the configuration:**

* The cron service is installed and running
* The cron daemon automatically starts on system boot
* A scheduled task runs every five minutes
* The file `/tmp/cron_text` is updated with the word `hello`

Cron automation is a foundational skill for DevOps engineers because many infrastructure tasks rely on scheduled execution.
