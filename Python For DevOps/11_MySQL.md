# Mastering MySQL with Python: A DevOps Guide

For a DevOps engineer, interacting with databases is a fundamental task. Whether you're managing application data, storing metrics, logging deployment statuses, or creating automation that relies on a persistent state, the ability to programmatically connect to and manipulate a database is essential. MySQL is one of the most popular open-source relational databases in the world, and Python provides powerful, easy-to-use libraries to interact with it.

This guide provides a complete, zero-to-hero walkthrough of using Python to work with MySQL. We will cover everything from the initial connection and basic CRUD (Create, Read, Update, Delete) operations to transaction management and real-world DevOps automation scenarios. By the end of this guide, you will be proficient in writing robust Python scripts to manage your MySQL databases.

---

### Table of Contents
1.  [**Part 1: Setup and Your First Connection**](#part-1-setup-and-your-first-connection)
    * [Prerequisites: Installing MySQL](#prerequisites-installing-mysql)
    * [Installing the Python Connector](#installing-the-python-connector)
    * [Establishing a Connection](#establishing-a-connection)
    * [Best Practice: Robust Connection Handling](#best-practice-robust-connection-handling)

2.  [**Part 2: The Cursor - Your Gateway to Execution**](#part-2-the-cursor---your-gateway-to-execution)
    * [What is a Cursor?](#what-is-a-cursor)
    * [Executing Your First Query](#executing-your-first-query)

3.  [**Part 3: Core Database Operations (CRUD)**](#part-3-core-database-operations-crud)
    * [**CREATE**: Creating Databases and Tables](#create-creating-databases-and-tables)
    * [**INSERT**: Adding Data to Tables](#insert-adding-data-to-tables)
    * [**The Golden Rule: Parameterized Queries to Prevent SQL Injection**](#the-golden-rule-parameterized-queries-to-prevent-sql-injection)
    * [**READ**: Fetching Data from Tables](#read-fetching-data-from-tables)
    * [**UPDATE**: Modifying Existing Data](#update-modifying-existing-data)
    * [**DELETE**: Removing Data](#delete-removing-data)

4.  [**Part 4: Managing Transactions**](#part-4-managing-transactions)
    * [What are Transactions? (The All-or-Nothing Principle)](#what-are-transactions-the-all-or-nothing-principle)
    * [Committing Changes with `connection.commit()`](#committing-changes-with-connectioncommit)
    * [Reverting Changes with `connection.rollback()`](#reverting-changes-with-connectionrollback)

5.  [**Part 5: Advanced Techniques & DevOps Scenarios**](#part-5-advanced-techniques--devops-scenarios)
    * [Reading Credentials from a Configuration File](#reading-credentials-from-a-configuration-file)
    * [Fetching Results as Dictionaries](#fetching-results-as-dictionaries)
    * [DevOps Scenario 1: Logging Deployment Status](#devops-scenario-1-logging-deployment-status)
    * [DevOps Scenario 2: A Database Health Check Script](#devops-scenario-2-a-database-health-check-script)

6.  [**Part 6: Best Practices Summary**](#part-6-best-practices-summary)
7.  [**Conclusion**](#conclusion)

---

## Part 1: Setup and Your First Connection
<a name="part-1-setup-and-your-first-connection"></a>

### Prerequisites: Installing MySQL
<a name="prerequisites-installing-mysql"></a>
Before you can connect with Python, you need a MySQL server to connect to. You can install one locally on your machine or use a cloud-based service (like Amazon RDS or a Docker container).

For local installation, you can use your system's package manager:
```bash
# On Debian/Ubuntu
sudo apt update
sudo apt install mysql-server

# On Red Hat/CentOS
sudo dnf install mysql-server

# On macOS (with Homebrew)
brew install mysql
```
After installation, make sure the service is running and you have a username and password.

### Installing the Python Connector
<a name="installing-the-python-connector"></a>
The most common library for connecting to MySQL is `mysql-connector-python`. It's recommended to work inside a Python virtual environment.

```bash
# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate  # (On macOS/Linux)
# venv\Scripts\activate  # (On Windows)

# Install the library
pip install mysql-connector-python
```

### Establishing a Connection
<a name="establishing-a-connection"></a>
The `mysql.connector.connect()` function is used to establish a connection. You provide credentials as arguments.

```python
import mysql.connector

try:
    connection = mysql.connector.connect(
        host="localhost",
        user="your_username",
        password="your_password"
    )

    if connection.is_connected():
        print("Successfully connected to MySQL database")

except mysql.connector.Error as e:
    print(f"Error connecting to MySQL: {e}")

finally:
    if 'connection' in locals() and connection.is_connected():
        connection.close()
        print("MySQL connection is closed")
```
**Note:** It's bad practice to hardcode credentials. We'll cover a better way later.

### Best Practice: Robust Connection Handling
<a name="best-practice-robust-connection-handling"></a>
The `try...except...finally` block is crucial.
* The `try` block attempts the connection.
* The `except` block catches any potential errors (e.g., wrong password, server is down).
* The `finally` block **always** runs, ensuring that the connection is closed, which prevents resource leaks.

---

## Part 2: The Cursor - Your Gateway to Execution
<a name="part-2-the-cursor---your-gateway-to-execution"></a>

### What is a Cursor?
<a name="what-is-a-cursor"></a>
Once you have a connection, you cannot execute queries directly on it. You need to create a **cursor** object. A cursor is like a controller that allows you to send commands to the database and fetch results. It keeps track of the state of the query.

### Executing Your First Query
<a name="executing-your-first-query"></a>
The `cursor.execute()` method is used to run SQL queries.

```python
import mysql.connector

try:
    connection = mysql.connector.connect(host="localhost", user="root", password="password")
    cursor = connection.cursor()
    
    # Execute a simple query to get the database version
    cursor.execute("SELECT VERSION()")
    
    # Fetch the result
    db_version = cursor.fetchone()
    print(f"Database version: {db_version[0]}")

except mysql.connector.Error as e:
    print(f"Error: {e}")

finally:
    if connection.is_connected():
        cursor.close()
        connection.close()
```

---

## Part 3: Core Database Operations (CRUD)
<a name="part-3-core-database-operations-crud"></a>

### **CREATE**: Creating Databases and Tables
<a name="create-creating-databases-and-tables"></a>
You can run any SQL DDL (Data Definition Language) statement with `cursor.execute()`.

```python
# ... (inside a try block with connection and cursor)
cursor.execute("CREATE DATABASE IF NOT EXISTS devops_db")
print("Database 'devops_db' created or already exists.")

cursor.execute("USE devops_db") # Switch to the new database

create_table_query = """
CREATE TABLE IF NOT EXISTS deployments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50),
    deployment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"""
cursor.execute(create_table_query)
print("Table 'deployments' created or already exists.")
```

### **INSERT**: Adding Data to Tables
<a name="insert-adding-data-to-tables"></a>
To add data, you use the `INSERT INTO` SQL statement.

```python
# ... (inside a try block)
app = "webapp"
version = "1.2.0"
status = "success"

insert_query = "INSERT INTO deployments (app_name, version, status) VALUES (%s, %s, %s)"
record = (app, version, status)

cursor.execute(insert_query, record)
connection.commit() # IMPORTANT: This saves the changes to the database

print(f"{cursor.rowcount} record inserted.")
```

### **The Golden Rule: Parameterized Queries to Prevent SQL Injection**
<a name="the-golden-rule-parameterized-queries-to-prevent-sql-injection"></a>
**NEVER** format your query using f-strings or string concatenation with user-provided data. This exposes you to **SQL Injection**, a major security vulnerability.

* **WRONG and DANGEROUS:** `cursor.execute(f"SELECT * FROM users WHERE name = '{user_input}'")`
* **CORRECT and SAFE:** `cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))`

The database connector will safely handle the substitution, sanitizing any malicious input.

### **READ**: Fetching Data from Tables
<a name="read-fetching-data-from-tables"></a>
After executing a `SELECT` query, you use fetch methods to retrieve the results.

* **`fetchone()`**: Returns the next single row as a tuple, or `None` if no more rows are available.
* **`fetchall()`**: Returns all remaining rows as a list of tuples. Be careful with large datasets as this can consume a lot of memory.
* **`fetchmany(size)`**: Returns the next `size` number of rows.

```python
# ... (inside a try block)
cursor.execute("SELECT * FROM deployments WHERE status = %s", ("success",))

records = cursor.fetchall()
print(f"Found {len(records)} successful deployments:")
for row in records:
    print(f"ID: {row[0]}, App: {row[1]}, Version: {row[2]}, Status: {row[3]}")
```

### **UPDATE**: Modifying Existing Data
<a name="update-modifying-existing-data"></a>
Use the `UPDATE` statement. **Always include a `WHERE` clause** to avoid updating every row in the table.

```python
# ... (inside a try block)
update_query = "UPDATE deployments SET status = %s WHERE id = %s"
data = ("failed", 1)

cursor.execute(update_query, data)
connection.commit()
print(f"{cursor.rowcount} record(s) updated.")
```

### **DELETE**: Removing Data
<a name="delete-removing-data"></a>
Use the `DELETE` statement. Like `UPDATE`, **always include a `WHERE` clause**.

```python
# ... (inside a try block)
delete_query = "DELETE FROM deployments WHERE id = %s"
record_id = (2,)

cursor.execute(delete_query, record_id)
connection.commit()
print(f"{cursor.rowcount} record(s) deleted.")
```

---

## Part 4: Managing Transactions
<a name="part-4-managing-transactions"></a>

### What are Transactions? (The All-or-Nothing Principle)
<a name="what-are-transactions-the-all-or-nothing-principle"></a>
A transaction is a sequence of operations performed as a single logical unit of work. The key principle is that **all** operations in the transaction must complete successfully. If any one of them fails, the entire transaction is rolled back, and the database is left unchanged. This ensures data integrity.

Think of transferring money: you must debit one account AND credit another. If the credit fails after the debit, you need to undo the debit.

### Committing Changes with `connection.commit()`
<a name="committing-changes-with-connectioncommit"></a>
By default, the MySQL connector does not automatically save changes (like `INSERT`, `UPDATE`, `DELETE`). The changes are pending within a transaction. You must explicitly call `connection.commit()` to make them permanent. If you close the connection without committing, the changes are lost.

### Reverting Changes with `connection.rollback()`
<a name="reverting-changes-with-connectionrollback"></a>
If an error occurs during a multi-step operation, you can call `connection.rollback()` inside an `except` block to undo all changes made since the last commit.

```python
# ... (inside a try block)
try:
    # Operation 1: Add a new server record
    cursor.execute("INSERT INTO servers (name, ip) VALUES (%s, %s)", ("new-api-01", "10.2.3.4"))
    
    # Operation 2: Update its status in another table (this will fail intentionally)
    cursor.execute("INSERT INTO server_status (server_id, status) VALUES (%s, %s)", (999, "pending")) # Assume server_id 999 doesn't exist

    connection.commit() # This line won't be reached
    print("Server added and status updated successfully.")

except mysql.connector.Error as e:
    print(f"An error occurred: {e}. Rolling back transaction.")
    connection.rollback() # Undo the INSERT from Operation 1
```

---

## Part 5: Advanced Techniques & DevOps Scenarios
<a name="part-5-advanced-techniques--devops-scenarios"></a>

### Reading Credentials from a Configuration File
<a name="reading-credentials-from-a-configuration-file"></a>
Store credentials in a separate config file (like `config.ini` or `.env`) and add it to your `.gitignore`.

```ini
# config.ini
[mysql]
host = localhost
user = root
password = your_password
database = devops_db
```

```python
import configparser

config = configparser.ConfigParser()
config.read('config.ini')
db_config = config['mysql']

connection = mysql.connector.connect(**db_config)
```

### Fetching Results as Dictionaries
<a name="fetching-results-as-dictionaries"></a>
Working with numeric indices (`row[0]`) can be confusing. You can tell the cursor to return rows as dictionaries, where keys are the column names.

```python
# Create the cursor as a dictionary cursor
dict_cursor = connection.cursor(dictionary=True)

dict_cursor.execute("SELECT * FROM deployments")
records = dict_cursor.fetchall()

for row in records:
    # Now you can access by column name!
    print(f"App: {row['app_name']}, Version: {row['version']}")
```

### DevOps Scenario 1: Logging Deployment Status
<a name="devops-scenario-1-logging-deployment-status"></a>
A Python function that could be called at the end of a CI/CD pipeline.
```python
def log_deployment(db_config, app_name, version, status):
    query = "INSERT INTO deployments (app_name, version, status) VALUES (%s, %s, %s)"
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        cursor.execute(query, (app_name, version, status))
        conn.commit()
        print("Deployment log saved successfully.")
    except mysql.connector.Error as e:
        print(f"Failed to log deployment: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
```

### DevOps Scenario 2: A Database Health Check Script
<a name="devops-scenario-2-a-database-health-check-script"></a>
A simple script to verify that the database is reachable and can be queried.
```python
def check_db_health(db_config):
    try:
        conn = mysql.connector.connect(**db_config, connection_timeout=5)
        if conn.is_connected():
            print("HEALTH CHECK: Database connection successful.")
            return True
    except mysql.connector.Error:
        print("HEALTH CHECK: Database connection failed.")
        return False
    finally:
        if 'conn' in locals() and conn.is_connected():
            conn.close()
```

## Part 6: Best Practices Summary
<a name="part-6-best-practices-summary"></a>
1.  **Always use parameterized queries** to prevent SQL injection.
2.  **Never hardcode credentials**. Store them in config files or environment variables.
3.  **Use `try...except...finally`** to handle errors and ensure connections are always closed.
4.  **Keep transactions short**. Commit or roll back as soon as a logical unit of work is done.
5.  **Use dictionary cursors** for more readable code when fetching data.
6.  **Close cursors and connections** when you are finished with them to free up resources.

## Conclusion
<a name="conclusion"></a>
Connecting Python to MySQL is a powerful combination for any DevOps engineer. It unlocks the ability to automate a vast range of tasks that depend on data persistence, from simple logging to complex system management. By mastering the fundamental patterns covered in this guide—robust connections, secure queries with parameterization, and reliable transaction management—you have built a solid foundation for creating professional, production-ready database automation scripts.
