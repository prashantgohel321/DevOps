# Linux Level 1, Task 11: Automated Find and Replace with `sed`

Today's task was a great exercise in a core skill for any system administrator: automating text manipulation within files. The objective was to replace all occurrences of a specific string in an XML file without manually opening the file. This is a common requirement for updating configuration files or templates.

I learned how to use the powerful `sed` (Stream Editor) command to perform this find-and-replace operation efficiently and non-interactively. This document is my first-person guide to that process, explaining the concepts and the command I used.

### The Task

My objective was to modify an XML file on the **backup server**. The specific requirements were:
-   The target file was `/root/nautilus.xml`.
-   I had to substitute all occurrences of the string `Text` with the string `Torpedo`.

### My Step-by-Step Solution

1.  **Connect to the Server:** I first logged into the backup server (`ssh clint@stbkp01`).

2.  **Execute the `sed` Command:** This was the core of the task. I used a single `sed` command to perform the replacement. I needed `sudo` because the file was in the `/root` directory.
    ```bash
    sudo sed -i 's/Text/Torpedo/g' /root/nautilus.xml
    ```

3.  **Verification:** The crucial final step was to confirm that the changes were made correctly. I used the `grep` command to search for the new string in the file.
    ```bash
    sudo grep Torpedo /root/nautilus.xml
    ```
    The command printed out all the lines that now contained "Torpedo," which was the definitive proof that my task was successful.

### Key Concepts (The "What & Why")

-   **`sed` (Stream Editor)**: `sed` is a powerful command-line utility for parsing and transforming text. While it can do many complex things, its most famous use is for find-and-replace operations. It's an essential tool for scripting because it can modify files non-interactively.
-   **In-Place Editing (`-i`)**: This is a critical flag. By default, `sed` reads a file, makes the changes, and prints the modified content to the terminal without changing the original file. The `-i` flag tells `sed` to edit the file **i**n-place, saving the changes directly back to the source file.
-   **The Substitution Command (`'s/find/replace/g'`)**: This is the "recipe" I gave to `sed`.
    -   `s`: This stands for **s**ubstitute.
    -   `/Text/`: This is the pattern to find.
    -   `/Torpedo/`: This is the string to replace it with.
    -   `g`: This is the **g**lobal flag. Without it, `sed` would only replace the *first* occurrence of "Text" on each line. The `g` flag is essential to ensure it replaces *all* occurrences throughout the entire file.

### Commands I Used

-   `sudo sed -i 's/Text/Torpedo/g' /root/nautilus.xml`: The main command for this task.
    -   `sed`: The Stream Editor utility.
    -   `-i`: Modifies the file **i**n-place.
    -   `'s/Text/Torpedo/g'`: The substitution command to replace all occurrences of `Text` with `Torpedo`.
    -   `/root/nautilus.xml`: The target file.
-   `sudo grep Torpedo /root/nautilus.xml`: My verification command. It searches for and prints all lines containing the word "Torpedo" in the specified file, proving the replacement worked.
  