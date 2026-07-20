## Agent skills

### Issue tracker

GitHub Issues using the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context — one `CONTEXT.md` plus `docs/adr/` at the repository root. See
`docs/agents/domain.md`.

### Pull request history

- Keep each pull-request branch linear and create one merge commit into `master`.
- Before merging, rebase the branch onto `origin/master`; do not merge `master`
  into the branch.
- After a rebase, update the remote branch only with `git push --force-with-lease`.
- If an automated branch cannot be safely rebased, recreate it from
  `origin/master` before merging.
