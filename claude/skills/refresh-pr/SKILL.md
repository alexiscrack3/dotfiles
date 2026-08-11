---
name: refresh-pr
description: Update the title and description of the current branch's pull request. Ensures the PR description follows the repo's PR template with all required sections filled in meaningfully. Also use when the user invokes "/refresh-pr".
---

# Updating Pull Request

Update the title and description of an existing pull request for the current branch in the current repository. Generates a title and description from the actual diff against the base branch.

## Arguments

Optional, e.g. `/refresh-pr --dry-run --template=custom`:

| Argument           | Effect                                                                              |
| ------------------ | ----------------------------------------------------------------------------------- |
| `--template=repo`  | Use the repo's own template                                                         |
| `--template=custom`| Use `~/.claude/skills/refresh-pr/custom_template.md`                                |
| `--template=claude`| Use `CLAUDE.md`                                                                     |
| `--template=<path>`| Use an explicit file path                                                           |
| `--template=ask`   | Force the template question even if a choice is remembered, and save the new answer  |
| `--dry-run`        | Do everything except the update — present the proposal, then stop                    |

An explicit `--template=` is a one-off override and does not change the repo's remembered default; use `--template=ask` to change it.

If an argument isn't recognized, stop and list the valid ones rather than guessing at what was meant.

## Keep the interruptions to a minimum

This skill should stop to ask the user at most **twice**: once to gather what the diff can't tell you (Step 5), and once for approval (Step 8). Often only once.

That budget is the point of Steps 4 and 5. Resolve the template silently whenever the answer is knowable, derive everything the diff already answers, and batch every remaining unknown into one `AskUserQuestion` call. A question whose answer you could have looked up costs more than it returns — the user invoked a skill to avoid doing this work themselves.

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

Parse the arguments first (see **Arguments** above) so `--template=` and `--dry-run` are known before anything asks the user a question. Then run these in parallel:

1. `git branch --show-current` — get current branch
2. `git status --porcelain` — check for uncommitted changes
3. `gh pr view --json number,title,body,baseRefName,url` — check for existing PR
4. `gh repo view --json nameWithOwner -q .nameWithOwner` — the `owner/repo` slug, used as the key for the remembered template choice in Step 4

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

### Step 4: Resolve the Template

A repo's template choice is stable — it is the same answer every time in a given repo. Resolve it without asking whenever possible. Work down this list and stop at the first hit:

**1. Explicit argument.** `--template=` from Step 0. Resolve `repo`/`custom`/`claude` to their paths; take any other value as a literal path.

**2. Remembered choice for this repo.**

```bash
jq -r --arg k "<owner/repo>" '.[$k] // empty' ~/.claude/refresh-pr-state.json 2>/dev/null
```

If the remembered path no longer exists, ignore it and fall through — a template that was deleted or renamed should not block the run.

**3. Exactly one candidate exists.** Discover what's available:

```bash
{ ls -1 .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md pull_request_template.md PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md docs/PULL_REQUEST_TEMPLATE.md 2>/dev/null; find .github/PULL_REQUEST_TEMPLATE -maxdepth 1 -name '*.md' 2>/dev/null; } | xargs -n1 realpath 2>/dev/null | sort -u
```

Two details in that command are load-bearing — run it as written:

- **`find` for the multi-template directory, not a `*.md` glob.** Under zsh a glob that matches nothing is a fatal error, not an empty expansion, so `.github/PULL_REQUEST_TEMPLATE/*.md` aborts the entire pipeline in every repo that lacks that directory — including repos that *do* have a normal template. The failure mode is silent and backwards: discovery returns nothing, and the skill asks a question it had the answer to.
- **`realpath | sort -u` to dedupe.** macOS filesystems are typically case-insensitive, so the upper- and lowercase spellings resolve to the same file; without this, one template counts as two candidates and triggers a needless question.

Add `~/.claude/skills/refresh-pr/custom_template.md` and `CLAUDE.md` to the candidate set. If the set has exactly one member, use it.

**4. Otherwise, ask** — but fold the question into the single round in Step 5 rather than spending a round trip on it. Order the options most-likely-first: repo template, then custom template, then `CLAUDE.md`. Once the user answers, remember it:

```bash
STATE=~/.claude/refresh-pr-state.json
jq -e . "$STATE" >/dev/null 2>&1 || echo '{}' > "$STATE"
tmp=$(mktemp) && jq --arg k "<owner/repo>" --arg v "<chosen path>" '.[$k]=$v' "$STATE" > "$tmp" && mv "$tmp" "$STATE"
```

Store **absolute** paths, not `~`-prefixed ones — the value is later read directly as a file path, where `~` is not expanded.

The `jq -e .` guard rewrites the file if it is missing, empty, or corrupt. A corrupt file therefore resets every repo's remembered choice, not just this one; that is the intended tradeoff, since the worst case is one extra question per repo rather than a hard failure.

Always state which template you resolved to and how — "using `.github/pull_request_template.md` (remembered for `shop/world`)". A sticky wrong answer is only correctable if it's visible, and that one line is what makes `--template=ask` discoverable.

Do not silently fall back when a resolved path turns out to be missing: say which path you expected, then ask.

### Step 5: Gather Missing Context — One Round Only

First, derive everything the diff already answers. Only then ask, in a **single** `AskUserQuestion` call — it takes up to four questions, which is enough for every gap below.

Ask about:

- **Template** — only if Step 4 landed on case 4. Put it first.
- **Monitoring/observability** — unless the diff adds logging or metrics, ask what the user plans to watch and which dashboards are relevant.
- **Tophatting steps** — you cannot know what was verified locally beyond unit tests. Ask what they did and what a reviewer should follow.
- **Related issues/docs** — ask only if nothing in the branch, the commits, or the existing body already references an issue.

Rules for this round:

- **One round, not one round per gap.** A second round is justified only if the first round's answers reveal a genuinely new unknown — not to ask something you could have bundled.
- **Skip the round entirely** when the diff and the existing body answer everything. Asking a question you already have the answer to is worse than not asking.
- Never ask about something already answered in the current body — it was saved in Step 0 for exactly this reason.
- If the user says "don't know" or "N/A", reflect that honestly in the description rather than padding with vague text.

If the user asked you to work autonomously, skip this round and fill from branch analysis alone. If information critical to assessing risk is missing, leave the PR in draft rather than guessing.

### Step 6: Generate Description

Read the PR template from the path resolved in Step 4. The template may change over time — always read the current version rather than relying on a cached copy. Fill every section with specifics from the actual changes.

The template supplies the *structure*; the saved body from Step 0 supplies anything a human already contributed. Build the new body by walking the template section by section, and for each one decide: does the current body already answer this? Keep it. Is it blank or stale? Write it from the diff. Then re-attach every preserved element from "Preserve what a human wrote" — checkbox state, images, closing keywords, bot regions — in its original position.

Before moving on, confirm that nothing in the saved body has silently vanished. Every image URL, every `- [x]`, and every `Closes #`/`Fixes #` reference in the old body must appear in the new one.

### Step 7: Useful links to include

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

### Step 8: Present for Approval

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

**If `--dry-run` was passed, stop here.** Present the title, the diff, and the body, say plainly that nothing was updated, and give the temp file path. Do not ask for approval — there is nothing to approve.

Otherwise ask for approval or edits using `AskUserQuestion`. Offer options like:

- "Looks good, update it"
- "Edit title only"
- "Edit description only"
- "Let me provide feedback"

This is the last stop before the update. Everything the user might need to decide — the diff, the removals, the resolved template — belongs in this one message, not spread across earlier questions.

If the user provides feedback, regenerate accordingly and re-present.

### Step 9: Update the PR

Once approved, update using the GitHub API directly. Do NOT use `gh pr edit` — it silently fails in some repos due to a GraphQL Projects Classic deprecation bug.

Pass the body by reference from the temp file written in Step 8. Never inline a long description into the shell command — backticks, quotes, and pipes in the body break the argument. If the user edited the description during approval, rewrite the temp file first so the file and the approved text cannot diverge.

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
- NEVER PATCH when `--dry-run` was passed, however clearly correct the result looks.
- NEVER spend a question on something the diff, the commits, or the existing body already answer.
