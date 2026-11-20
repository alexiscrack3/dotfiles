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
| `--prefix`         | Start the title with a `[category]` prefix (see Step 3). Without it, no prefix is added |

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
- **Bot- and app-managed regions.** Meteorite and Graphite stack tables, Codecov/coverage summaries, Sourcegraph banners, dependency-bot notes. Graphite is retired, but older PRs still carry the stack table it wrote into the body; clobbering a stack table breaks stack navigation for every PR in the stack. Reproduce these byte for byte, in their original position — do not reformat, unwrap, or "fix" them, including their line breaks.
- **Reviewer-facing annotations.** `<details>` blocks, "review commit-by-commit," "ignore the rename in X," and similar notes to reviewers. One exception: a `<details>` wrapper around the risk and tophatting sections is removed, not preserved (see "Never collapse the risk and tophatting sections" below). Keep the sections' content. A second exception: a `<details>` block that holds a Mermaid diagram is replaced by a Drawr board link (see "Add a Drawr diagram only when it helps" below).
- **Existing prose that is already specific and still accurate.** If a section answers its question concretely and the diff has not invalidated it, keep the author's wording. Rewrite a section only when it is empty, still holds unfilled template scaffolding, or has gone stale against the current diff.

Two things are *not* human content and should be replaced: unfilled `<!-- ... -->` template comments, and sections left blank.

When you cannot tell whether a block was written by a human, a bot, or a previous run of this skill, **preserve it**. An unnecessary leftover line costs a reviewer a second; a destroyed screenshot or a reset checklist costs real information.

## Procedure

### Step 0: Preflight Checks

Parse the arguments first (see **Arguments** above) so `--template=` and `--dry-run` are known before anything asks the user a question. Then run these in parallel:

1. `git branch --show-current` — get current branch
2. `git status --porcelain` — check for uncommitted changes

**Branch check**: If on `main` or `master`, stop and tell the user there's nothing to update.

**Clean working tree check**: If `git status --porcelain | grep -v '^??'` produces any output (modified or staged tracked files), stop and tell the user they have uncommitted changes. Suggest they commit or stash first before updating the PR. List the dirty files. Untracked files (`??`) should be ignored — they are irrelevant to PR metadata updates.

**Find where the PR lives.** A PR is either a Delta PR (`shop/world` and other repos whose `origin` is `delta.shopify.io`) or a GitHub PR, and the two have separate number spaces — a Delta PR number means nothing to `gh`, and vice versa. `gs` and Gitstream/Meteorite are retired; never use `gs`. Check Delta first:

```bash
git remote get-url origin
dt pr list --head "<branch>" --json 2>/dev/null
```

`dt` prints Git warnings on stderr; the `2>/dev/null` keeps them out of the JSON so `jq` can parse it. Do not drop stderr on anything else.

- **`origin` is on `delta.shopify.io` and the array is non-empty → Delta.** Take `.[0].number`, then read the full PR with `dt pr view <N> --json 2>/dev/null`. Use `dt` for every PR command below. The base branch is `.base.ref`, the browser link is `.html_url` (not `.url`, which is an API link), and the repo key for Step 4 is `.base.repo.full_name` (for example `shop/world`).
- **`origin` is not Delta → try GitHub:**

  ```bash
  gh pr view --json number,title,body,baseRefName,url
  gh repo view --json nameWithOwner -q .nameWithOwner
  ```

  If `gh pr view` succeeds, the PR is on GitHub. Use `gh` for every PR command below. The base branch is `baseRefName`, the link is `url`, and the repo key for Step 4 is the `nameWithOwner` slug.

A `shop/world` PR numbered 2,000,000 to 2,199,999 is a Meteorite PR imported into Delta as read-only history. `dt pr edit` refuses it with `pull_read_only`. Stop and point the user to the `migrate-meteorite-stack-to-delta` skill.

Do not use `gt`. Graphite was retired at Shopify; the `gt` on PATH is a placeholder that only prints a migration notice.

**PR check**: If neither provider finds a PR, stop and tell the user there is no open PR for this branch. Suggest they create one first — `dt submit` on Delta, `gh pr create` elsewhere.

If all checks pass, show the user the provider, current PR title, URL, and continue — e.g. "PR #2348323 is on Delta, using `dt`."

Every later step has a command for each provider:

| Job | Delta (`dt`) | GitHub (`gh`) |
| --- | --- | --- |
| Read the PR | `dt pr view <N> --json 2>/dev/null` | `gh pr view --json number,title,body,baseRefName,url` |
| Changed files | `dt pr diff <N> --name-only` | `gh pr diff --name-only` |
| Full diff | `dt pr diff <N>` | `gh pr diff` |
| Update title and body | `dt pr edit <N> -t "<title>" -b "$(cat <file>)"` (Step 9) | `gh api repos/{owner}/{repo}/pulls/<N> -X PATCH ...` (Step 9) |
| Verify | `dt pr view <N> --json 2>/dev/null` | `gh pr view --json title,body,url` |

**Save the current body.** Before generating anything, write the existing body to disk so it can be merged against and diffed later:

```bash
# Delta
dt pr view <PR_NUMBER> --json 2>/dev/null | jq -r '.body // ""' > /tmp/pr-<PR_NUMBER>-body-current.md
# GitHub
gh pr view --json body --jq .body > /tmp/pr-<PR_NUMBER>-body-current.md
```

Read that file. It is the input to the merge described in "Preserve what a human wrote" — not a formality. If it is empty, this is a fresh PR body and there is nothing to preserve.

### Step 1: Gather Diff

Run these in parallel:

1. Changed files — `dt pr diff <N> --name-only` (Delta) or `gh pr diff --name-only` (GitHub)
2. Full diff — `dt pr diff <N>` (Delta) or `gh pr diff` (GitHub)
3. `git log --oneline <base>..HEAD` — commit history on this branch (use the base branch from Step 0: `.base.ref` for Delta, `baseRefName` for GitHub). In a large repo such as `shop/world`, use `origin/<base>` and fetch only that ref first if it is stale: `git fetch --no-tags origin refs/heads/<base>:refs/remotes/origin/<base>`.

### Step 2: Filter the Diff

Remove generated/noise files from your analysis. Focus on the meaningful changes only.

### Step 3: Generate Title

Generate a PR title as a concise description: `Concise description`.

**Prefix only on request.** Add a `[category]` prefix (`[category] Concise description`) only when `--prefix` was passed. Without it, never add one, even if the template, the commits, or a previous run used one. If the current title already starts with a `[category]` prefix, keep it as it is: not adding a prefix does not mean removing the author's.

**Categories** (with `--prefix`, pick the single most prominent one):

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

- Under 72 characters total, including a `[category]` prefix when there is one
- Imperative mood ("Add feature" not "Added feature")
- Summarize the main purpose, not every file touched
- With `--prefix`, if multiple categories apply, pick the dominant one

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
- **Explain the problem in prose.** Write "What are you trying to accomplish with this PR?" as one or two short paragraphs in plain language, not bullet points. Say what is wrong or missing, why it matters, and what this PR changes to fix it. Write for a reader who does not know the code: short sentences, everyday words, no jargon that the paragraph does not explain. Put an issue-closing keyword (`Closes #123`) on its own line after the paragraphs.
- Use bullet points in the other sections.
- Do not include the co-author trailer in the description (that belongs in commits).
- **Never collapse the risk and tophatting sections.** Write "What have we done to minimize risks?" and "Tophatting steps" as ordinary `##` sections, never inside a `<details>`/`<summary>` block (for example `<summary>Risks and tophatting</summary>`). This overrides any template or zone `AGENTS.md` that asks for them to be collapsed. If the current body already wraps them in `<details>`, unwrap them and keep their content.
- **Add a Drawr diagram only when it helps.** Use one when the change alters a flow that is hard to follow in prose: calls across several classes or services, a reordered pipeline, a new branch in control flow, or a state change. Skip it for small, local, or mechanical changes (renames, config, copy, a one-method fix). A diagram that repeats one bullet adds noise. Draw it on a [Drawr](https://drawr.quick.shopify.io) board, not in Mermaid: people can edit the board, and it stays readable at any width.
  - **Load the `drawr` skill first.** It tells you how to get the CLI and the live `agents.txt`. Download both fresh each run and read `agents.txt` before you write any ops. Pass `--as Claude` on every write.
  - **Link it at the end of "What are you trying to accomplish with this PR?"**, as one line with no `<details>` block:

    ```markdown
    Diagram: [<what it shows>](https://drawr.quick.shopify.io/b/<id>) (Drawr board). Green boxes are new in this PR.
    ```

  - **Find the board before you make one.** If the current body already links a `drawr.quick.shopify.io/b/<id>` board, `read` it and update that board in place: change only the objects that are stale against the diff, and keep anything a person added. Make a new board (`new --title "<PR title>"`) only when the body has no board link.
  - **An existing Mermaid block is replaced.** Redraw its content on a Drawr board that matches the current diff, and swap the whole `<details>`/` ```mermaid ` block for the link line. Name this in the Step 8 change summary as "Mermaid diagram replaced by Drawr board".
  - **`--dry-run` writes nothing to Drawr.** Do not create or change a board. Put the link line in the proposed body with `<drawr board link>` as the URL, and list the planned columns and boxes in the Step 8 message instead.
  - **Layout:**
    - One `section` per flow (for example "Write", "Read", "Delete", or "Before" and "After"), side by side. Each section runs top to bottom.
    - Rounded rectangles for steps, diamonds for decisions, cylinders for stores (cache, database, bucket). Label every decision branch (`yes`, `no`, `hit`, `miss`).
    - Colour only what changed. New steps: `"fill": "green", "stroke": "green"`. Old, wrong steps: `"fill": "red", "stroke": "red"`. Stop or skip outcomes: `"fill": "gray"`. Everything else: `"fill": "white"`. Use palette names, never hex, so the board follows the viewer's theme.
    - 2 to 4 words per box, plus an optional second line with the class, method or a key number (`Rails.cache write\nRecorder, 48 h`). Use plain `text` for labels that hold `_` (flag, metric and method names), because markdown reads `_` as italic.
    - Long identifiers wrap mid-word inside diamonds. Keep decision text short ("Capture flag on?") and put the full flag or metric names in a sticky note beside the sections.
    - Add a few sticky notes for facts the boxes cannot show: failure handling, why a path is skipped, and a colour key ("Green = new in this PR").
    - Follow `agents.txt` "Leave room": 100 to 160 between connected shapes, 60 padding inside sections, and spread out anything `apply` reports as crowded.
  - Use real class, method, flag, and metric names from the diff. Never draw a step the diff does not contain. Read the code paths the diff touches so each box matches it.
  - **Check it by looking.** After `apply`, run `png --out /tmp/pr-<PR_NUMBER>-drawr.png` and view the image. Fix labels that wrap mid-word, overlap, or are cut off, then look again.
  - If the `quick` CLI is not signed in or Drawr fails, leave the diagram out, keep any existing diagram as it is, and say so in Step 8. Do not fall back to a new Mermaid block.
  - On a refresh, keep an existing board if it still matches the diff. Update it if it is stale. If the change no longer needs a diagram, remove the link line, and leave the board alone: people may still use it.
  - Give the board link in the Step 8 message, so the user can open it before they approve.
- **Number every tophatting step `1.`** Write each step in "Tophatting steps" as `1. <step>`, never `2.`, `3.` and so on. Markdown renders the list as 1, 2, 3, so a step can be added, removed or moved without renumbering the rest. This applies to every numbered list in that section, including a list nested under a step. When the current body numbers its tophatting steps `1.`, `2.`, `3.`, change them all to `1.` and name it in the Step 8 change summary as "Tophatting steps renumbered to `1.`".
- **Never hard-wrap.** Write each paragraph, bullet, and table row as a single unbroken line, however long — GitHub soft-wraps it in both the rendered view and the edit box. The only newlines are ones that carry Markdown meaning: between paragraphs, between list items, and inside fenced code blocks. This holds even when the PR's current body is hard-wrapped — rewrite it unwrapped rather than mirroring its line breaks.

### Step 8: Present for Approval

Write the proposed body to `/tmp/pr-<PR_NUMBER>-body.md`, then show the user, in this order:

1. **Change summary** — one short list: sections added, rewritten, removed, and kept as they were. Name every removal.
2. **Title and body diff** — in one fenced ` ```diff ` block, so the terminal colours `-` lines red and `+` lines green. Put the title first as two lines (`- <current title>` / `+ <proposed title>`), then the body diff against the saved current body:

   ```bash
   git diff --no-index --no-prefix -- /tmp/pr-<PR_NUMBER>-body-current.md /tmp/pr-<PR_NUMBER>-body.md
   ```

   Paste the output in full. Never shorten, summarize, or elide hunks — a removal hidden in a skipped hunk is the defect this step exists to catch.
3. **Word diff for rewritten paragraphs** — bodies are never hard-wrapped, so a one-word edit marks a whole paragraph as `-` and `+`. When a changed line differs in only a few words, also show the word-level diff, in a plain fenced block:

   ```bash
   git diff --no-index --no-prefix --word-diff=plain -- /tmp/pr-<PR_NUMBER>-body-current.md /tmp/pr-<PR_NUMBER>-body.md
   ```

   It marks changes inline as `[-old words-]{+new words+}`. Keep the line diff for sections that were added or removed whole; the word diff is for the edits inside paragraphs. Skip it when every change is a whole added or removed block.
4. **Temp file path** — `/tmp/pr-<PR_NUMBER>-body.md`, so the user can open the full proposed body.

Do not render the full proposed description by default: it pushes the diff off the screen. Render it only on `--dry-run` or when the user asks for it.

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

Pass the body by reference from the temp file written in Step 8. Never inline a long description into the shell command — backticks, quotes, and pipes in the body break the argument. If the user edited the description during approval, rewrite the temp file first so the file and the approved text cannot diverge.

**Delta** — use `dt pr edit`. It has no body-file flag, so pass the file through a quoted command substitution; the shell does not re-parse its contents, so backticks and quotes in the body are safe:

```bash
dt pr edit <PR_NUMBER> -t "<title>" -b "$(cat /tmp/pr-<PR_NUMBER>-body.md)"
```

Then verify by diffing the saved body against the live one; empty output means the update landed exactly:

```bash
dt pr view <PR_NUMBER> --json 2>/dev/null | jq -r '.title, .html_url'
diff <(dt pr view <PR_NUMBER> --json 2>/dev/null | jq -r '.body') /tmp/pr-<PR_NUMBER>-body.md
```

Show the user the `html_url`.

**GitHub** — use the GitHub API directly. Do NOT use `gh pr edit` — it silently fails in some repos due to a GraphQL Projects Classic deprecation bug.

```bash
gh api repos/{owner}/{repo}/pulls/<PR_NUMBER> -X PATCH \
  -f title="<title>" \
  -F body=@/tmp/pr-<PR_NUMBER>-body.md
```

`{owner}` and `{repo}` are substituted by `gh` from the current directory's git remote — do not hardcode a repo. `@file` expansion only works with `-F`, so `body` uses `-F` while `title` stays on `-f`.

Then verify with `gh pr view --json title,body,url` and show the user the updated PR URL.

## Important Rules

- NEVER create a new PR. This skill only updates existing ones.
- NEVER mix providers. A Delta PR is read and updated with `dt` only; a GitHub PR with `gh` only.
- NEVER use `gs`. Gitstream and Meteorite are retired.
- NEVER push commits. This skill only updates PR metadata.
- NEVER proceed if the working tree is dirty — the PR description should reflect what's already pushed.
- NEVER fabricate changes. Only describe what's actually in the diff.
- NEVER include prompt instructions or meta-commentary in the generated title or description.
- NEVER drop an image, video, or attachment from the existing body. Those URLs are one-time uploads and cannot be recovered.
- NEVER reset a checked checkbox to unchecked, and never remove an issue-closing keyword or a bot-managed region.
- NEVER PATCH without having shown the user the body diff, including its removals.
- NEVER PATCH when `--dry-run` was passed, however clearly correct the result looks.
- NEVER spend a question on something the diff, the commits, or the existing body already answer.
- NEVER wrap the risk or tophatting sections in a `<details>` block.
