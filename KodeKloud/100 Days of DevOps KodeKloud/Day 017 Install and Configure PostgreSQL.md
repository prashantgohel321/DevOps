# DevOps Day 17: PostgreSQL Database and User Management

Today's task was a dive into the world of database administration, a critical skill for any DevOps role. The objective was to prepare a PostgreSQL database server for a new application. This wasn't just about making sure the database was running; it was about setting up the proper security and isolation for the new application's data.

I learned how to interact with PostgreSQL from the command line, create dedicated users and databases, and grant permissions. This entire process is a real-world application of the "Principle of Least Privilege" and is fundamental to building secure and maintainable systems.

## Table of Contents
- [The Task](#the-task)
- [My Step-by-Step Solution](#my-step-by-step-solution)
- [Why Did I Do This? (The "What & Why")](#why-did-i-do-this-the-what--why)
- [Deep Dive: The Principle of Least Privilege in Databases](#deep-dive-the-principle-of-least-privilege-in-databases)
- [Common Pitfalls](#common-pitfalls)
- [Exploring the Commands Used](#exploring-the-commands-used)

---

### The Task
<a name="the-task"></a>
My objective was to configure the pre-installed PostgreSQL server on the Nautilus database server. The specific requirements were:
1.  Create a new database user (a role) named `kodekloud_aim`.
2.  Set a specific password (`ksH85UJjhb`) for this new user.
3.  Create a new, empty database named `kodekloud_db6`.
4.  Grant the `kodekloud_aim` user full permissions on the `kodekloud_db6` database.

---

### My Step-by-Step Solution
<a name="my-step-by-step-solution"></a>
The entire process was performed on the command line of the database server (`stdb01`).

#### Step 1: Gaining Administrative Access
First, I connected to the database server (`ssh peter@stdb01`). To manage PostgreSQL, I needed to become the `postgres` Linux user, which is the superuser for the database.
```bash
sudo -u postgres -i
```
This command gave me an interactive shell as the `postgres` user. From there, I could access the database's administrative shell, `psql`.
```bash
psql
```
My command prompt changed to `postgres=#`, indicating I was now inside the database.

#### Step 2: Executing the SQL Commands
Inside the `psql` shell, I ran three distinct SQL commands to accomplish the task. It's crucial to remember that every SQL command must end with a semicolon `;`.

1.  **Create the User:** I created the new role and assigned its password in a single command.
    ```sql
    CREATE USER kodekloud_aim WITH PASSWORD 'ksH85UJjhb';
    ```
>    The shell responded with `CREATE ROLE`, confirming success.

2.  **Create the Database:** Next, I created the dedicated database for the application.
    ```sql
    CREATE DATABASE kodekloud_db6;
    ```
>    The shell responded with `CREATE DATABASE`.

3.  **Grant Permissions:** Finally, I connected the user and the database by granting the necessary privileges.
    ```sql
    GRANT ALL PRIVILEGES ON DATABASE kodekloud_db6 TO kodekloud_aim;
    ```
>   The shell responded with GRANT

---

### Step 3: Verification
While still inside `psql`, I used some of its helpful meta-commands (which start with a `\`) to verify my work.

- To check if the user was created, I ran `\du`. I saw `kodekloud_aim` in the list of roles.

- To check the database and permissions, I ran `\l`. I saw `kodekloud_db6` in the list, and its access privileges correctly listed the `kodekloud_aim` user.

- After confirming, I typed `\q` to exit `psql` and `exit` to log out of the `postgres` user session, successfully completing the task.

---

### Why Did I Do This? (The "What & Why")
<a name="why-did-i-do-this-the-what--why"></a>

- **PostgreSQL**: Often called Postgres, it's a very popular and powerful open-source **relational** database. It's known for its reliability, which makes it a common choice for enterprise applications.

- **psql**: This is the primary `command-line tool` for interacting with a `PostgreSQL` server. It's an **interactive shell** where I can run `SQL` queries directly and perform administrative tasks.

- **Peer Authentication**: This is a security mechanism. The reason I had to use `sudo -u postgres` is that the database, by default, trusts that if I am the postgres user on the Linux system, I should also be allowed to log in as the `postgres superuser` inside the database. It authenticates me based on my operating system "peer."

- **Separation of Concerns**: The whole point of this task was to create a separate user and a separate database for the new application. This is a fundamental security and design principle. It ensures that the application can only access its own data and that if its credentials were ever compromised, the attacker's access would be limited to only that one database, not the entire server.

---

### Deep Dive: The Principle of Least Privilege in Databases
<a name="deep-dive-the-principle-of-least-privilege-in-databases"></a>
This task was a perfect demonstration of applying the **Principle of Least Privilege**. This security concept states that a user or application should only be granted the minimum level of access (or privileges) necessary to perform its required functions.

**Why not use the postgres superuser?** I could have just given the application the password for the postgres superuser. This would have been easy, but incredibly dangerous. The postgres user can do anything on the database server, including reading data from other applications' databases or even deleting them entirely. If the application were compromised, the attacker would have the "keys to the kingdom."

#### How I Applied the Principle:

1. I created a **new user** (kodekloud_aim) that had no privileges by default.

2. I created a **new database** (kodekloud_db6) that was empty and isolated.

3. I then **granted privileges** only where they were needed. The `GRANT` command created a specific link: kodekloud_aim can access kodekloud_db6. This user cannot see or touch any other database on the server.

This ensures that the application is sandboxed. It has just enough power to do its job, and no more.

---

### Common Pitfalls
<a name="common-pitfalls"></a>

- **Forgetting the Semicolon `;`**: This is the most common mistake when using `psql`. If you forget the semicolon at the end of a command and press Enter, psql will just wait for you to finish the command, which can be confusing.

- **Incorrect `sudo` Usage**: Trying to run psql directly (e.g., sudo psql) might work on some systems but can fail on others depending on the authentication setup. Using the two-step `sudo -u postgres -i` and then `psql` is the most reliable method for peer authentication.

- **Password in Quotes**: When specifying the password in the `CREATE USER` command, it must be enclosed in single `quotes`.

- **Granting Insufficient Privileges**: While `GRANT ALL PRIVILEGES` was correct for this task, in a real-world production environment, I might grant more specific privileges, like only `SELECT`, `INSERT`, `UPDATE`, `DELETE`, and not allow the user to change the database structure itself.

---

### Exploring the Commands Used
<a name="exploring-the-commands-used"></a>

- **`sudo -u postgres -i`**: The command to get an interactive shell as the postgres user.

- **`psql`**: Starts the PostgreSQL interactive terminal.

- **`CREATE USER [name] WITH PASSWORD '[password]';`**: The SQL command to create a new user (role) with login rights and set their password.

- **`CREATE DATABASE [name];`**: The SQL command to create a new, empty database.

- **`GRANT ALL PRIVILEGES ON DATABASE [db_name] TO [user_name];`**: The SQL command to give a user full control over a specific database.

- **`\du`**: A psql meta-command to describe users (list all roles).

- **`\l`**: A psql meta-command to list all databases and their owners/permissions.

- **`\q`**: The psql meta-command to quit the interactive terminal.