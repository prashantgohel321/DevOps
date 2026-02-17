# Linux Level 02 Day 04: Modifying Text Safely with sed

This document explains how to use the Linux stream editor `sed` to modify text files in a controlled and predictable way. The task focuses on two very common real-world operations: removing entire lines based on a condition and replacing a specific word without accidentally modifying similar-looking words. 

The operations are performed on a file located on an application server and the results are written to new files instead of modifying the original source. This approach mirrors how changes are usually tested and validated in professional environments.

---

<br>
<br>

- [Linux Level 02 Day 04: Modifying Text Safely with sed](#linux-level-02-day-04-modifying-text-safely-with-sed)
  - [What the Task Required](#what-the-task-required)
  - [Connecting to the Server and Preparing the Environment](#connecting-to-the-server-and-preparing-the-environment)
  - [Removing Lines Containing a Specific Word](#removing-lines-containing-a-specific-word)
  - [Replacing a Word Without Touching Similar Words](#replacing-a-word-without-touching-similar-words)
  - [Confirming That the Changes Are Correct](#confirming-that-the-changes-are-correct)
  - [How sed Achieves This Internally](#how-sed-achieves-this-internally)
  - [Word Boundaries and Why They Matter](#word-boundaries-and-why-they-matter)
  - [Redirection Versus In-Place Editing](#redirection-versus-in-place-editing)
  - [Commands Worth Exploring Further](#commands-worth-exploring-further)
  - [Core Learning](#core-learning)

<br>
<br>

## What the Task Required

The objective was to modify the contents of the file `/home/BSD.txt` on Nautilus App Server 2.

Two separate outputs were required.

First, every line containing the word `copyright` had to be removed, and the remaining content saved into `/home/BSD_DELETE.txt`.

Second, every occurrence of the standalone word `the` had to be replaced with the word `is`, while ensuring that words such as `their`, `them`, or `breathe` remained unchanged. The result of this operation had to be saved into `/home/BSD_REPLACE.txt`.

The original file was not allowed to be modified directly.

---

<br>
<br>

## Connecting to the Server and Preparing the Environment

The task was performed on App Server 2. After connecting using SSH, administrative privileges were required because new files had to be created under `/home`, which may not always be writable by a normal user.

```bash
ssh steve@stapp02
# Password: Am3ric@
sudo su -
cd /home/
```

Once inside `/home`, all paths become easier to reason about and commands remain explicit.

---

<br>
<br>

## Removing Lines Containing a Specific Word

The first operation required deleting every line that contained the word `copyright`. This is a line-based operation, which aligns perfectly with how `sed` processes input.

```bash
sed '/copyright/d' /home/BSD.txt > /home/BSD_DELETE.txt
```

The pattern between the first pair of slashes tells `sed` which lines to look at. Any line containing the string `copyright` matches this condition. The letter `d` instructs `sed` to delete those matching lines.

Internally, `sed` reads the file one line at a time. When a line matches the pattern, it is dropped. When it does not match, it is passed through unchanged.

The redirection operator `>` writes the final output to a new file. The original file is only read, never altered. This makes the operation safe and reversible.

---

<br>
<br>

## Replacing a Word Without Touching Similar Words

The second operation required more precision. Replacing text blindly can easily introduce errors. For example, replacing `the` everywhere without constraints would incorrectly transform words like `them` or `breathe`.

To avoid this, the replacement must target only full words.

```bash
sed 's/\bthe\b/is/g' /home/BSD.txt > /home/BSD_REPLACE.txt
```

The `s` command tells `sed` to substitute text. The pattern `\bthe\b` defines where the substitution is allowed to occur.

A word boundary represents the edge of a word. It matches positions where a word character meets a non-word character such as a space, punctuation mark, or the beginning or end of a line. By placing a boundary on both sides of `the`, the match succeeds only when `the` stands alone as a complete word.

The replacement string `is` is inserted wherever the match occurs. The `g` flag ensures that all matches on a line are replaced rather than just the first one.

As with the previous command, output redirection writes the transformed content into a new file, preserving the original data.

---

<br>
<br>

## Confirming That the Changes Are Correct

Verification is essential whenever automated text processing is involved. Simple checks can confirm both that the unwanted content is gone and that no unintended changes were introduced.

To confirm that all lines containing `copyright` were removed:

```bash
grep "copyright" /home/BSD_DELETE.txt
```

This command should produce no output, which indicates that the word does not appear anywhere in the file.

To confirm that all standalone occurrences of `the` were replaced:

```bash
grep -w "the" /home/BSD_REPLACE.txt
```

The `-w` option forces `grep` to search for whole words only. If nothing is printed, it confirms that no full word `the` remains.

To confirm that related words were not affected:

```bash
grep "them" /home/BSD_REPLACE.txt
grep "their" /home/BSD_REPLACE.txt
```

Seeing these words unchanged proves that the word boundary logic behaved correctly.

---

<br>
<br>

## How sed Achieves This Internally

`sed` operates as a stream editor. It reads input line by line, applies rules, and writes output immediately. It does not load the entire file into memory, which makes it efficient even for large files.

In the deletion task, lines matching the pattern are discarded before being written to output. In the substitution task, matching sections of a line are replaced while the rest of the line remains intact.

Because `sed` processes streams, it works well with pipes, redirection, and automation pipelines commonly used in DevOps workflows.

---

<br>
<br>

## Word Boundaries and Why They Matter

Without boundaries, pattern matching is purely textual. A pattern like `the` matches anywhere those three letters appear together. This is rarely what is desired when modifying configuration files or documentation.

Word boundaries introduce context. They allow the command to distinguish between a complete word and a sequence of characters inside a larger word. This distinction is critical when performing substitutions in scripts, logs, or configuration files.

Some `sed` implementations also support `\<` and `\>` to represent the beginning and end of a word. These forms serve the same purpose and are sometimes clearer when reading commands.

---

<br>
<br>

## Redirection Versus In-Place Editing

The task explicitly required writing results to new files. This is why output redirection was used.

Redirecting output reads from the source file and writes the modified stream elsewhere. The source remains untouched.

In contrast, using the `-i` option edits files in place. While useful, in-place editing is riskier and should only be used when the changes are fully understood and backups exist.

---

<br>
<br>

## Commands Worth Exploring Further

To preview changes without saving them:

```bash
sed 's/\bthe\b/is/g' /home/BSD.txt | less
```

To perform case-insensitive substitution:

```bash
sed 's/\bthe\b/is/gi' /home/BSD.txt
```

To delete lines using multiple patterns:

```bash
sed '/copyright\|license/d' /home/BSD.txt
```

Exploring these variations builds confidence in using `sed` safely and effectively.

---

<br>
<br>

## Core Learning

This task demonstrates that safe text manipulation is about precision, not just command knowledge. By understanding how `sed` processes text, how word boundaries restrict matches, and how redirection protects original data, it becomes possible to automate changes without unintended side effects. These skills are fundamental when managing configuration files and logs in real systems.
