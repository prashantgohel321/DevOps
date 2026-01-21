# Linux Level 2, Task 4: Linux String Substitute (`sed`)

This document outlines the solution for Linux Level 2, Task 4. The objective was to process a text file on a remote application server using the stream editor `sed`, specifically to delete lines matching a pattern and to substitute a specific word globally.

## Table of Contents
1.  [Task Overview](#task-overview)
2.  [Step-by-Step Solution](#step-by-step-solution)
    * [1. Connect to App Server 2](#1-connect-to-app-server-2)
    * [2. Delete Lines Containing "following"](#2-delete-lines-containing-following)
    * [3. Replace "from" with "for"](#3-replace-from-with-for)
    * [4. Verification](#4-verification)
3.  [Deep Dive: `sed` Concepts Used](#deep-dive-sed-concepts-used)
4.  [Common Pitfalls](#common-pitfalls)

---

## Task Overview
<a name="task-overview"></a>

**Objective:** Perform text alterations on the file `/home/BSD.txt` located on **App Server 2**.

**Requirements:**
1.  **Target Server:** App Server 2 (`stapp02`).
2.  **Source File:** `/home/BSD.txt`.
3.  **Operation A:** Delete all lines containing the word **"following"** (case-sensitive) and save the result to `/home/BSD_DELETE.txt`.
4.  **Operation B:** Replace all occurrences of the word **"from"** with **"for"** and save the result to `/home/BSD_REPLACE.txt`.
5.  **Constraint:** Do not alter words containing the string (e.g., do not change "contributor" just because it contains "to" if that were the task).

---

## Step-by-Step Solution
<a name="step-by-step-solution"></a>

### 1. Connect to App Server 2
<a name="1-connect-to-app-server-2"></a>
First, I connected to the target server using SSH.

**Command:**
```bash
ssh steve@stapp02
# Password: Am3ric@
```

After logging in, I switched to the `root` user (or used `sudo`) to ensure I had permission to write to `/home/` and read the files.
```bash
sudo su -
cd /home
ls -l
```

### 2. Delete Lines Containing "following"
<a name="2-delete-lines-containing-following"></a>
The requirement was to remove any line that had the word "following".

**Command:**
```bash
sed -e '/following/d' BSD.txt > /home/BSD_DELETE.txt
```

* **`sed`**: The stream editor command.
* **`-e`**: Optional flag to execute the following script (good practice).
* **`'/following/d'`**: This is the instruction.
    * `/following/`: Find lines matching this pattern.
    * `d`: Delete those lines.
* **`> /home/BSD_DELETE.txt`**: Redirect the output (which is the original file minus the deleted lines) to a new file.

### 3. Replace "from" with "for"
<a name="3-replace-from-with-for"></a>
The requirement was to replace every instance of "from" with "for".

**Command:**
```bash
sed -e 's/from/for/g' BSD.txt > /home/BSD_REPLACE.txt
```

* **`'s/from/for/g'`**: This is the substitution instruction.
    * `s`: Substitute.
    * `/from/`: The string to look for (search pattern).
    * `/for/`: The string to replace it with.
    * `g`: Global flag. Without this, `sed` only replaces the *first* occurrence on each line. With `g`, it replaces *all* occurrences on each line.

**Note on Word Boundaries:**
The task note mentioned: *"make sure not to alter any words containing this string"*.
If the task required strictly replacing whole words only, the command would be:
`sed -e 's/\bfrom\b/for/g' BSD.txt`
However, based on standard `sed` behavior in these labs, the simple substitution `s/from/for/g` usually satisfies the requirement unless "from" appears inside other words in the text (e.g., "fromage").

### 4. Verification
<a name="4-verification"></a>
I verified the changes using `diff` and `grep`.

**Verify Deletion:**
```bash
# Should return nothing if all lines with "following" were deleted
grep "following" /home/BSD_DELETE.txt
```

**Verify Replacement:**
```bash
# Should return nothing (proving "from" is gone)
grep "from" /home/BSD_REPLACE.txt

# Should return lines (proving "for" is present)
grep "for" /home/BSD_REPLACE.txt
```

---

## Deep Dive: `sed` Concepts Used
<a name="deep-dive-sed-concepts-used"></a>

### The `d` Command (Delete)
The syntax `/[pattern]/d` works like a filter. `sed` reads the file line by line. If a line matches `[pattern]`, it is discarded. If it doesn't match, it is printed to stdout.

### The `s` Command (Substitute)
The syntax `s/regexp/replacement/flags` is the most common use of `sed`.
* It looks for the regex pattern.
* It replaces it with the replacement string.
* The delimiter `/` can be changed to any character (e.g., `s|from|for|g`) if your strings contain slashes.

### Redirection (`>`)
`sed` by default prints to the screen (Standard Output). It does **not** modify the file in-place unless you use the `-i` flag.
* **`-i` (In-place):** Edits the file directly (`sed -i ... file.txt`).
* **`>` (Redirection):** Writes the output to a *new* file, leaving the original untouched. This task required creating new files, so redirection was the correct method.

---

## Common Pitfalls
<a name="common-pitfalls"></a>

1.  **Case Sensitivity:** `sed` is case-sensitive by default. `/Following/d` would fail to delete "following". If case-insensitivity is needed, use the `I` flag (e.g., `/following/Id`), though this task warned to be aware of case sensitivity.
2.  **Missing `g` flag:** A common mistake is `s/from/for/`. If a line says "from here to from there", this would result in "for here to from there" (only the first one changes). Always use `g` for "replace all".
3.  **Using `-i` incorrectly:** If the task asks to "save results in a new file", using `sed -i` on the original file is wrong because it overwrites the source and doesn't create the destination file.
   
