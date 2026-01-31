# Repository Restructuring While Preserving Commit History

## Context and Objective

A single Git repository has been used as a shared workspace for multiple independent projects over a period of time. As these projects have matured, the need has emerged to separate selected projects into their own dedicated repositories while retaining their original commit history. The requirement is to keep the existing repository unchanged and create new repositories for specific projects with their full, real commit lineage preserved.

## Core Requirement

Two projects, **02 Server Manager** and **03 Server Inventory Live**, must exist in their own independent GitHub repositories while continuing to remain in the original repository. The separation must preserve commit history accurately, without squashing or recreating commits.

## Conceptual Approach

Git provides a mechanism called *subtree splitting*, which allows the history of a specific directory to be extracted and rewritten as a standalone branch. Internally, Git scans the complete commit graph, selects only those commits that modified the specified directory, and reconstructs them in correct chronological order as if the directory had always been the repository root. The original repository content and history remain untouched.

## Practical Execution Using Git Subtree Split

A fresh clone is used to avoid affecting any local working state. The project directory is extracted into a new branch and pushed to a new remote repository.

```bash
git clone https://github.com/you/main-repo.git
cd main-repo
```

## Extracting the Server Manager Project

```bash
git subtree split -P "02 Server Manager" -b server-manager
git push https://github.com/you/server-manager.git server-manager:main
```

## Extracting the Server Inventory Live Project

```bash
git subtree split -P "03 Server Inventory Live" -b inventory-live
git push https://github.com/you/server-inventory-live.git inventory-live:main
```

## Resulting State

The original repository continues to contain all projects exactly as before. Each newly created repository contains only its respective project, placed at the repository root, with all historical commits preserved faithfully. No history is copied, squashed, or approximated; the commit graph remains authentic.

## Summary

This approach achieves clean repository separation, maintains historical accuracy, avoids additional tooling dependencies, and ensures that long-term project ownership and maintenance become simpler and more scalable.
