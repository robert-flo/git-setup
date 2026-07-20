# Contribuir

Gracias por mejorar `git-setup`.

## Preparación

Necesitas Bash, Git y ShellCheck. Ejecuta las pruebas antes de abrir un cambio:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
shellcheck git-setup helper/set_variable.sh bin/git-setup lib/global_fn.sh tests/*.sh
```

## Cambios seguros

- Mantén los cambios pequeños y con una sola responsabilidad.
- Añade una prueba de interfaz pública para cada comportamiento nuevo.
- No incluyas tokens, claves privadas, correos personales ni rutas de tu equipo.
- Conserva los flujos existentes de `verify`, `setup`, `test` y `clean`.

## Commits

Usa mensajes imperativos y atómicos, por ejemplo:

```text
feat: add SSH signing profile
test: cover safe cleanup
```
