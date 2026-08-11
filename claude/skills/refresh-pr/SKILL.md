---
name: refresh-pr
description: Update the title and description of the current branch's pull request. Ensures the PR description follows the repo's PR template with all required sections filled in meaningfully. Also use when the user invokes "/refresh-pr".
---

# Updating Pull Request

Update the title and description of an existing pull request for the current branch in the current repository. Generates a title and description from the actual diff against the base branch.

## How to fill the template

1. Analyze all commits on the branch (not just the latest) using `git log` and `git diff` against the base branch
2. Identify: what changed, why, what's at risk, what flags or experiments gate it
3. Fill every section with specifics from the actual changes — generic answers and lists of files changed waste reviewers' time
4. Never fabricate information you don't have. A made-up dashboard link or ops channel is worse than asking — it gives false confidence to reviewers and deploy captains who rely on this information being accurate

## Generated/Noise File Patterns

Exclude these files from summaries (same as `/commit`):

- `**/graphql/__generated__/**` — Generated GraphQL types
- `**/*.lock` / `**/lock.json` / `**/lockfile` — Lock files
- `**/*.rbi` — Sorbet RBI type files
- `**/api/app/graphql/persisted/**` — Persisted GraphQL queries
- `**/persisted-documents.json` — Persisted query documents

If the PR's changes are _exclusively_ to these files, include them.

## Ask before you guess

After analyzing the branch, explicitly ask about anything you're uncertain on. Common gaps:

- **Monitoring/observability**: Unless the diff adds explicit logging/metrics, ask what the user plans to monitor and which dashboards are relevant.
- **Tophatting steps**: You may not know what has been tested locally (outside of unit tests). Ask what they've done and what steps a reviewer should follow.
- **Related issues/docs**: The conversation may not have referenced an issue. Ask if there's one to link.

Use the `AskUserQuestion` tool to gather all missing information in a single round. This gives the user a structured way to respond rather than having to parse a wall of text. If the user provides the information, incorporate it. If they say they don't know or it's not applicable, reflect that honestly in the PR description rather than padding with vague text.

The user may have asked you to work autonomously, in which case you should do your best to fill in the template based on the branch analysis alone. However, if any critical information is missing that would impact reviewers' ability to assess risk or understand the change, it's better to leave the PR in draft.

## Preserve what a human wrote

This skill rewrites a PR body that people and bots have already written into. Refreshing is a **merge**, not a replace. The existing body is authoritative for anything you cannot derive from the diff — and some of it cannot be recovered once overwritten.

Carry these over verbatim:

- **Checked checkboxes.** A `- [x]` stays `- [x]`. These are the author's attestations — silently resetting one to `- [ ]` retracts a claim they made, and a deploy captain reads the result as "not done yet." Only a checkbox that is genuinely new to the template starts unchecked.
- **Images, videos, and attachments.** `![...](https://github.com/user-attachments/...)`, `<img>`, `<video>`. The upload URLs are one-time and cannot be regenerated — dropping one destroys it permanently. This is the only truly unrecoverable loss in this procedure.
- **Issue-closing keywords.** `Closes #123`, `Fixes #123`, `Resolves ABC-456`. Removing one un-links the issue and breaks auto-close on merge.
- **Bot- and app-managed regions.** Graphite stack tables, Codecov/coverage summaries, Sourcegraph banners, dependency-bot notes. Graphite writes its stack table into the body itself, so clobbering it breaks stack navigation for every PR in the stack. Reproduce these byte for byte, in their original position — do not reformat, unwrap, or "fix" them, including their line breaks.
- **Reviewer-facing annotations.** `<details>` blocks, "review commit-by-commit," "ignore the rename in X," and similar notes to reviewers.
- **Existing prose that is already specific and still accurate.** If a section answers its question concretely and the diff has not invalidated it, keep the author's wording. Rewrite a section only when it is empty, still holds unfilled template scaffolding, or has gone stale against the current diff.

Two things are *not* human content and should be replaced: unfilled `<!-- ... -->` template comments, and sections left blank.

When you cannot tell whether a block was written by a human, a bot, or a previous run of this skill, **preserve it**. An unnecessary leftover line costs a reviewer a second; a destroyed screenshot or a reset checklist costs real information.

## Procedure

### Step 0: Preflight Checks

Run these in parallel:

1. `git branch --show-current` — get current branch
2. `git status --porcelain` — check for uncommitted changes
3. `gh pr view --json number,title,body,baseRefName,url` — check for existing PR

**Branch check**: If on `main` or `master`, stop and tell the user there's nothing to update.

**Clean working tree check**: If `git status --porcelain | grep -v '^??'` produces any output (modified or staged tracked files), stop and tell the user they have uncommitted changes. Suggest they commit or stash first before updating the PR. List the dirty files. Untracked files (`??`) should be ignored — they are irrelevant to PR metadata updates.

**PR check**: If `gh pr view` fails (exit code non-zero), stop and tell the user there is no open PR for this branch. Suggest they create one first (e.g. with `gh pr create` or the `/graphite` skill if available).

If all checks pass, show the user the current PR title, URL, and continue.

**Save the current body.** Before generating anything, write the existing body to disk so it can be merged against and diffed later:

```bash
gh pr view --json body --jq .body > /tmp/pr-<PR_NUMBER>-body-current.md
```

Read that file. It is the input to the merge described in "Preserve what a human wrote" — not a formality. If it is empty, this is a fresh PR body and there is nothing to preserve.

### Step 1: Gather Diff

Run these in parallel:

1. `gh pr diff --name-only` — list of changed files
2. `gh pr diff` — the full diff
3. `git log --oneline <base>..HEAD` — commit history on this branch (use the `baseRefName` from Step 0)

### Step 2: Filter the Diff

Remove generated/noise files from your analysis. Focus on the meaningful changes only.

### Step 3: Generate Title

Generate a PR title using this format: `[category] Concise description`

**Categories** (pick the single most prominent one):

| Category   | When to use                                      |
| ---------- | ------------------------------------------------ |
| `feat`     | A new feature                                    |
| `fix`      | A bug fix                                        |
| `refactor` | Code restructuring without behavior change       |
| `chore`    | Non-code changes (configs, deps, scripts)        |
| `docs`     | Documentation only                               |
| `test`     | Adding or fixing tests                           |
| `perf`     | Performance improvements                         |
| `style`    | Formatting, whitespace, naming (no logic change) |
| `ci`       | CI/CD configuration changes                      |
| `build`    | Build system or dependency changes               |

**Title rules**:

- Under 72 characters total (including the `[category]` prefix)
- Imperative mood ("Add feature" not "Added feature")
- Summarize the main purpose, not every file touched
- If multiple categories apply, pick the dominant one

### Step 4: Choose Template

Before generating the description, ask the user which PR template to use. Always ask — do not silently infer based on which files exist.

Use `AskUserQuestion` with these three options:

- **Repo template** — `.github/pull_request_template.md`
- **Custom template** — `~/.claude/skills/refresh-pr/custom_template.md`
- **Claude.md** - `CLAUDE.md`

After the user picks, verify the chosen file exists. If it doesn't, tell the user the file is missing and ask again — do not silently fall back to the other template.

### Step 5: Generate Description

Read the PR template from the path selected in Step 4. The template may change over time — always read the current version rather than relying on a cached copy. Fill every section with specifics from the actual changes.

The template supplies the *structure*; the saved body from Step 0 supplies anything a human already contributed. Build the new body by walking the template section by section, and for each one decide: does the current body already answer this? Keep it. Is it blank or stale? Write it from the diff. Then re-attach every preserved element from "Preserve what a human wrote" — checkbox state, images, closing keywords, bot regions — in its original position.

Before moving on, confirm that nothing in the saved body has silently vanished. Every image URL, every `- [x]`, and every `Closes #`/`Fixes #` reference in the old body must appear in the new one.

### Step 6: Useful links to include

When filling in the template, reference these where relevant:

- **Dashboards**: [Shop App](https://observe.shopify.io/d/ScH_SG04z/shop-app) | [Shop Pay](https://observe.shopify.io/d/4WyxJ3A4k/shop-pay-main)
- **Observe errors**: [Error Management (shop-server)](https://observe.shopify.io/a/observe/errors?r=%7B%22from%22%3A%22now-3d%22%2C%22to%22%3A%22now%22%7D&f=%7B%22resource.service.name%22%3A%5B%22shop-server%22%5D%7D)
- **Feature flags**: `https://experiments.shopify.io/flags/<handle>` (link to the specific flag if the change is gated)

**Description rules**:

- Length proportional to the size of the changes. Small PRs get short descriptions; large PRs can be longer. Always as brief as possible.
- Simple language. Write for clarity, not impressiveness.
- Do not mention generated/noise files unless they are the focus of the PR.
- Omit a section if it truly doesn't apply (e.g. no Test Plan needed for a docs-only change).
- Use bullet points, not paragraphs.
- Do not include the co-author trailer in the description (that belongs in commits).
- **Never hard-wrap.** Write each paragraph, bullet, and table row as a single unbroken line, however long — GitHub soft-wraps it in both the rendered view and the edit box. The only newlines are ones that carry Markdown meaning: between paragraphs, between list items, and inside fenced code blocks. This holds even when the PR's current body is hard-wrapped — rewrite it unwrapped rather than mirroring its line breaks.

### Step 7: Present for Approval

Write the proposed body to `/tmp/pr-<PR_NUMBER>-body.md`, then show the user:

1. **Current title** → **Proposed title**
2. **What changes in the body** — a diff against the saved current body:

   ```bash
   git diff --no-index --no-prefix -- /tmp/pr-<PR_NUMBER>-body-current.md /tmp/pr-<PR_NUMBER>-body.md
   ```

3. **Proposed description** (rendered in full)

The diff is the point of this step, not a supplement to it. A rendered body looks correct precisely when something has been quietly dropped — a missing screenshot or an unchecked box is invisible in the new version alone and obvious as a `-` line. Read the removals before presenting: if the diff removes an image, a checked box, a closing keyword, or a bot region, that is a defect in your merge. Fix it and re-diff rather than asking the user to approve it.

If the diff is empty, the body is already accurate. Say so and skip the update rather than issuing a no-op PATCH that churns the PR's edit history.

Call out every removal explicitly in your summary so the user is deciding about deletions rather than discovering them later.

Ask for approval or edits using `AskUserQuestion`. Offer options like:

- "Looks good, update it"
- "Edit title only"
- "Edit description only"
- "Let me provide feedback"

If the user provides feedback, regenerate accordingly and re-present.

### Step 8: Update the PR

Once approved, update using the GitHub API directly. Do NOT use `gh pr edit` — it silently fails in some repos due to a GraphQL Projects Classic deprecation bug.

Pass the body by reference from the temp file written in Step 7. Never inline a long description into the shell command — backticks, quotes, and pipes in the body break the argument. If the user edited the description during approval, rewrite the temp file first so the file and the approved text cannot diverge.

```bash
gh api repos/{owner}/{repo}/pulls/<PR_NUMBER> -X PATCH \
  -f title="<title>" \
  -F body=@/tmp/pr-<PR_NUMBER>-body.md
```

`{owner}` and `{repo}` are substituted by `gh` from the current directory's git remote — do not hardcode a repo. `@file` expansion only works with `-F`, so `body` uses `-F` while `title` stays on `-f`.

Then verify with `gh pr view --json title,body,url` and show the user the updated PR URL.

## Important Rules

- NEVER create a new PR. This skill only updates existing ones.
- NEVER push commits. This skill only updates PR metadata.
- NEVER proceed if the working tree is dirty — the PR description should reflect what's already pushed.
- NEVER fabricate changes. Only describe what's actually in the diff.
- NEVER include prompt instructions or meta-commentary in the generated title or description.
- NEVER drop an image, video, or attachment from the existing body. Those URLs are one-time uploads and cannot be recovered.
- NEVER reset a checked checkbox to unchecked, and never remove an issue-closing keyword or a bot-managed region.
- NEVER PATCH without having shown the user the body diff, including its removals.
