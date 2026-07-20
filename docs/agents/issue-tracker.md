# Issue tracker: GitHub

Las incidencias y los requisitos de este repositorio viven en GitHub Issues.
Usa la CLI `gh` para consultarlas y gestionarlas.

## Convenciones

- Crear una incidencia: `gh issue create --title "..." --body "..."`.
- Leer una incidencia: `gh issue view <number> --comments`.
- Listar incidencias: `gh issue list --state open`.
- Comentar una incidencia: `gh issue comment <number> --body "..."`.
- Cerrar una incidencia: `gh issue close <number> --comment "..."`.

La incidencia se crea en el repositorio configurado como `origin`.

## Pull requests como fuente de triage

**PRs como fuente de solicitudes: no.**
