# Controlling Stage Execution in GitLab CI Based on Commit or Variables

## Scenario Overview

In CI/CD environments, it is common to have multiple stages such as build, test, deploy, or update_state. In some situations, you may want to skip a specific stage without disabling the entire pipeline.

GitLab provides flexible control using commit messages, CI variables, branch conditions, and built-in pipeline skip keywords.

This document explains how to:

* Skip a single stage using commit messages
* Skip the entire pipeline using built-in flags
* Use variables for controlled skipping
* Understand how GitLab decides whether a job runs or not

---

# Understanding the Core Concept

GitLab evaluates each job using `rules:`. These rules determine whether a job should run, skip, or wait for manual execution.

When a pipeline starts, GitLab reads:

* Commit message
* Branch name
* Environment variables
* Pipeline trigger type

Based on these values, it decides which jobs execute.

---

# Skipping a Specific Stage Using Commit Message

If the requirement is to skip only one job (for example `update_state`) but keep the rest of the pipeline running, define a rule based on commit message.

Example configuration:

```yaml
update_state:
  stage: update_state
  rules:
    - if: '$CI_COMMIT_MESSAGE =~ /\[skip-state\]/'
      when: never
    - when: on_success
  script:
    - echo "Updating state..."
```

Explanation:

* `$CI_COMMIT_MESSAGE` is a predefined GitLab variable.
* `=~` is a regular expression match.
* If `[skip-state]` appears in the commit message, the job will not run.
* Otherwise, it runs normally.

Commit example:

```bash
git commit -m "Testing change [skip-state]"
```

Only the `update_state` job is skipped. The rest of the pipeline executes.

---

# Skipping the Entire Pipeline Using Built-in Keywords

GitLab supports special commit message keywords:

* `[skip ci]`
* `[ci skip]`

Example:

```bash
git commit -m "Minor documentation update [skip ci]"
```

When this is pushed:

* GitLab does not create a pipeline at all.
* No jobs or stages execute.

This mechanism is built-in and requires no YAML configuration.

Use this only when you truly want to bypass the entire CI process.

---

# Skipping a Stage Using CI Variable (Recommended for Production)

Instead of relying on commit messages, controlled skipping using CI variables is cleaner.

Example:

```yaml
update_state:
  stage: update_state
  rules:
    - if: '$SKIP_STATE == "true"'
      when: never
    - when: on_success
  script:
    - echo "Updating state..."
```

To skip the job:

* Run the pipeline manually
* Add variable: `SKIP_STATE=true`

This approach avoids embedding control logic inside commit messages.

---

# Running a Stage Only on a Specific Branch

Sometimes a stage should run only on `main`.

Example:

```yaml
update_state:
  stage: update_state
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: on_success
    - when: never
```

Now `update_state` runs only on the main branch.

---

# Understanding Divergent Control Paths

Different skipping mechanisms serve different purposes:

| Method          | Scope             | Recommended Use            |
| --------------- | ----------------- | -------------------------- |
| `[skip ci]`     | Entire pipeline   | Minor change, no CI needed |
| Commit tag rule | Single job        | Developer-controlled skip  |
| CI variable     | Single job        | Controlled production skip |
| Branch rule     | Conditional stage | Environment-based logic    |

---

# Recommended Practice

* Do not comment out jobs in `.gitlab-ci.yml`.
* Prefer `rules:` for job control.
* Use variables for controlled, auditable pipeline behavior.
* Use `[skip ci]` only when intentionally bypassing the entire pipeline.

This keeps pipeline behavior predictable, maintainable, and production-safe.

---

# Summary

You can skip stages in GitLab based on:

1. Commit message pattern
2. Manual CI variable
3. Branch name
4. Built-in `[skip ci]` keyword

For selective stage skipping, use `rules:`.
For full pipeline skipping, use `[skip ci]`.

Understanding how GitLab evaluates job rules ensures clean control over pipeline execution.
