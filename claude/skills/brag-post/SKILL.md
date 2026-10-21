---
name: brag-post
description: Write a fun, emoji-rich Slack brag post that explains what a pull request shipped, for teammates and staff who did not read the code. Works with Delta PRs (shop/world), legacy GitHub PRs, or the current branch's PR. Use when the user asks for a "brag post", "Slack post about this PR", "announce this PR", "shout-out for what shipped", or "explain this PR for Slack".
---

# Brag Post

Turn a pull request into a short Slack post that shows off what shipped. The post is for
people who will not read the diff. By default, only produce the text. Never send it to
Slack unless the user explicitly asks. If they ask, create a draft with
`slack_send_message_draft` (call `slack_who_am_i` first) instead of posting.

## 1. Read the PR

Never write the post from memory or from the conversation alone. Read the PR itself.

Find the PR:

- A `delta.shopify.io/<owner>/<repo>/pull/<N>` link, or a shop/world number of 2,200,000 or
  more, is a Delta PR. Read the live Delta skill first
  (`curl -fsSL https://delta.shopify.io/SKILL.md`), then run:
  ```bash
  dt pr view <N> --comments
  ```
- A shop/world number from 2,000,000 to 2,199,999 is an imported Meteorite PR. Use
  `dt pr view <N>` too.
- A lower number, or a `github.com` link, is a GitHub PR. Use `gh pr view <N> --comments`.
- No PR given: use the checked-out branch's PR (`dt pr view` with no argument).

Collect:

- Title, description, state (merged, open or draft).
- Screencast, demo, dashboard or Observe links in the description.
- Review threads that changed the result (for example, a reviewer found an edge case and
  the author fixed it). These often become a good bullet.

If the description is thin, read the diff for the user-facing parts:

```bash
dt pr diff <N> | head -400     # or: gh pr diff <N>
```

Look for new UI, new endpoints, removed limits, speed-ups, numbers. Skip refactors and
test-only files unless they are the point of the PR.

If the PR is not merged, say so to the user and word the post as "coming soon" or ask
whether to wait.

## 2. Write the post

Use Slack markdown: `*bold*` works in Slack, but `**bold**` also renders when pasted from
the terminal into the Slack composer. Prefer `**bold**` to match what the user sees here.

Structure:

```
<emoji> **<Headline: the benefit, not the code change>** <emoji>

<1–2 sentences: the problem people had, and what they can do now.> <emoji>

**What's new** ✨
- <emoji> **<Feature>.** <One short sentence.>
- ... (3–6 bullets, most visible first)

**<Safety / Privacy / Performance — pick what fits>** 🔒
- <emoji> <How risk was kept low: no PII, no new tables, flag-gated, revert-safe, tests.>

🎬 [Watch the screencast](<url>)      ← only if one exists
🔗 [PR #<N>](<url>)

<Short call to action, e.g. "Go try it!"> <emoji>
```

Rules:

- Lead with the benefit to people ("You can now…"), not the implementation ("Added a
  Stimulus controller…").
- One idea per bullet. Short sentences. Plain words. Explain any jargon in a few words
  right after it, for example "localStorage (storage inside your browser)".
- Use emojis on the headline, on each bullet, and on section titles. Pick ones that match
  the content (⭐ favourites, ⚡ speed, 🐛 fix, 🔒 privacy, 📉 cost, 🧹 cleanup). Do not stack
  more than two in a row.
- Use real numbers from the PR (latency, counts, limits). Never invent metrics, users or
  impact the PR does not show.
- Keep it under about 200 words. A brag post that needs scrolling gets skipped.
- Use the PR's own link format. For shop/world the org is `shop`, never `Shopify`.
- Do not include customer data, buyer emails, shop IDs or secrets, even if the PR
  description has examples. Generic test accounts like `@myshopify.io` addresses can be
  left out.
- Do not @-mention people unless the user asks.

## 3. Hand it over

Print the post between two `---` lines so it is easy to copy. Then tell the user, in one
line, that it was not sent and they can paste it into Slack. If the user asks for a
different tone (shorter, more formal, no emojis, a thread reply), rewrite only the post.
