# Linux Level 02 Task 06: Using find to Identify and Quarantine Specific Files Safely

This document explains how the Linux `find` command was used to identify potentially malicious `.php` files on an application server and quarantine them into a separate directory while preserving their original directory hierarchy. The objective is not simply to copy files, but to do so in a way that maintains forensic integrity. Preserving the original path structure ensures that later analysis can determine where each file originally resided.

The task was performed on App Server 3 and involved searching a web application directory for all files ending in `.php`, then copying those files into a controlled location without flattening their paths.

---

<br>
<br>

- [Linux Level 02 Task 06: Using find to Identify and Quarantine Specific Files Safely](#linux-level-02-task-06-using-find-to-identify-and-quarantine-specific-files-safely)
  - [Understanding the Real Objective](#understanding-the-real-objective)
  - [Step 1: Access the Target Server with Proper Privileges](#step-1-access-the-target-server-with-proper-privileges)
  - [Step 2: Prepare the Destination Directory](#step-2-prepare-the-destination-directory)
  - [Step 3: Locate and Copy Files While Preserving Structure](#step-3-locate-and-copy-files-while-preserving-structure)
  - [Alternative Method Using xargs](#alternative-method-using-xargs)
  - [Verification of Results](#verification-of-results)
  - [Internal Behavior of find](#internal-behavior-of-find)
  - [Safety Considerations Before Running in Production](#safety-considerations-before-running-in-production)
  - [Result of This Task](#result-of-this-task)


<br>
<br>

## Understanding the Real Objective

The requirement was not only to locate `.php` files. It was to copy them while keeping their parent directories intact. If directory structure is lost, context is lost. A file named `index.php` could exist in multiple subdirectories. If copied into a single flat folder, it would be impossible to determine its source location.

Therefore, the solution needed to satisfy four conditions:

* Search only inside `/var/www/html/ecommerce`
* Match only files ending with `.php`
* Avoid matching directories
* Copy the files to `/ecommerce` while preserving full directory hierarchy

---

<br>
<br>

## Step 1: Access the Target Server with Proper Privileges

The web directory may require elevated privileges to read. Writing to the root filesystem also requires administrative access.

```bash
ssh banner@stapp03

sudo su -
```

Operating as root ensures read access to web files and write access to `/ecommerce`.

---

<br>
<br>

## Step 2: Prepare the Destination Directory

Before copying any files, the destination must exist.

```bash
mkdir -p /ecommerce
```

The `-p` option ensures the directory is created only if it does not already exist and prevents errors if it is already present.

---

<br>
<br>

## Step 3: Locate and Copy Files While Preserving Structure

The core of this task is the `find` command combined with controlled execution of `cp`.

```bash
find /var/www/html/ecommerce -type f -name "*.php" -exec cp --parents {} /ecommerce \;
```

This command performs multiple operations in a single pipeline.

The starting directory `/var/www/html/ecommerce` defines where the search begins. `find` recursively traverses all subdirectories from this point downward.

The option `-type f` restricts matches to regular files. Without this constraint, symbolic links, directories, or other file types could match patterns unintentionally.

The condition `-name "*.php"` filters results to filenames ending in `.php`. Quotes prevent the shell from expanding `*.php` before `find` processes it.

The `-exec` action instructs `find` to execute a command for every file that matches the criteria. The placeholder `{}` is replaced with the full path of each matched file. The sequence terminates with `\;`, which tells `find` where the command ends.

The key element is `cp --parents`. Normally, copying a file into `/ecommerce` would result in a flat structure where only filenames are preserved. The `--parents` option instructs `cp` to recreate the entire original directory path inside the destination directory.

For example, if a matched file is:

```
/var/www/html/ecommerce/admin/config.php
```

It will be copied as:

```
/ecommerce/var/www/html/ecommerce/admin/config.php
```

This ensures that the source context is fully retained.

---

<br>
<br>

## Alternative Method Using xargs

An alternative method uses `xargs`, which can be more efficient when processing a very large number of files.

```bash
find /var/www/html/ecommerce -type f -name "*.php" | xargs -I {} cp --parents {} /ecommerce
```

This version pipes the output of `find` into `xargs`, which executes the copy command for each file. However, this approach must be used carefully. If filenames contain spaces or special characters, the basic pipe method may break.

A safer variant uses null separators:

```bash
find /var/www/html/ecommerce -type f -name "*.php" -print0 | xargs -0 -I {} cp --parents {} /ecommerce
```

The `-print0` and `-0` combination ensures correct handling of complex filenames.

---

<br>
<br>

## Verification of Results

After execution, confirm that files were copied and structure was preserved.

```bash
find /ecommerce
```

If the `tree` utility is available, it provides a visual representation.

```bash
tree /ecommerce
```

You should see directory paths beginning with `/ecommerce/var/www/html/ecommerce/` followed by subdirectories and `.php` files.

---

<br>
<br>

## Internal Behavior of find

The `find` command performs a depth-first traversal of the directory tree. It evaluates each file against the specified conditions in sequence. When conditions are satisfied, associated actions such as `-exec` are triggered.

Conditions are evaluated left to right. If multiple conditions are chained, they function as logical AND operations unless explicitly modified. In this command, a file must satisfy both `-type f` and `-name "*.php"` to trigger the copy operation.

Understanding this evaluation order prevents accidental broad matches that could copy unintended files.

---

<br>
<br>

## Safety Considerations Before Running in Production

Before copying or modifying large sets of files, it is good practice to test the search pattern without executing the action.

```bash
find /var/www/html/ecommerce -type f -name "*.php"
```

Review the output. If it matches expectations, then add the `-exec` portion.

For extremely sensitive environments, consider redirecting output to a log file for auditing.

```bash
find /var/www/html/ecommerce -type f -name "*.php" > /root/php_file_list.txt
```

This ensures traceability of what was identified.

---

<br>
<br>

## Result of This Task

After completing these steps, all `.php` files inside the specified directory tree are quarantined under `/ecommerce`, and their original hierarchical structure is preserved. This configuration supports forensic analysis, security inspection, and remediation planning without altering the live application structure.

Mastering this pattern makes `find` a powerful investigative and remediation tool in DevOps and security workflows.
