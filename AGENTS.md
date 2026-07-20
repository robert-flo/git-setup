## Agent skills

### Issue tracker

GitHub Issues usando `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context — un `CONTEXT.md` + `docs/adr/` en la raíz. See `docs/agents/domain.md`.

### Historial de pull requests

- Mantener lineal la rama de cada pull request y crear un único merge commit hacia `master`.
- Antes de fusionar, rebasar la rama sobre `origin/master`; no fusionar `master` dentro de la rama.
- Después de un rebase, actualizar la rama remota únicamente con `git push --force-with-lease`.
- Si una rama automatizada no puede rebasarse de forma segura, recrearla desde `origin/master` antes de fusionarla.
