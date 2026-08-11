## What are you trying to accomplish with this PR?

<!--
- Link the issue this PR closes (e.g. Closes #1234)
- Explain the *why* in one or two sentences — what problem does this solve, or what does it unlock?
- Keep it brief; reviewers can read the diff for the *what*.
-->

## How will you know if it works/doesn't work?

<!--
Observability and verification:
- Logs / metrics / Observe dashboards you'll watch after rollout
- Specific error rates or thresholds that would indicate regression
- Tophatting performed locally (link Spin URL if applicable)
- Tests added — name them, don't just say "added tests"
-->

## What have we done to minimize risks?

<!--
- Feature flags / experiments gating this change (link to experiments.shopify.io)
- Killswitches available
- Tests that exercise the risky paths
- Existing patterns reused rather than new abstractions introduced
- Rollout plan (canary → 1% → 10% → 100%, etc.)
-->

## Tophatting steps

<!--
Step-by-step instructions a reviewer can follow to verify this manually.
1. Pull the branch and `dev up`
2. Specific URL / console command / GraphQL query to run
3. Expected result
Be concrete. "Test the flow" is not a tophatting step.
-->

## Before you deploy

- [ ] All required tests pass in CI
- [ ] Feature flag(s) configured in production (if applicable)
- [ ] Dashboards/alerts identified to monitor post-deploy
- [ ] Rollback plan understood (revert PR, kill flag, etc.)
- [ ] Linked issue updated with deploy notes (if applicable)
