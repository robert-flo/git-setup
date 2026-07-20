# git-setup

`git-setup` prepara una configuración de Git reproducible y separada de tus
dotfiles: archivos de configuración, identidad, firma de commits y un flujo
guiado para GitHub, SSH y GPG.

## Instalación

Clona el repositorio y ejecuta el binario desde su raíz:

```bash
git clone https://github.com/robert-flo/git-setup---hermes-agent-era.git
cd git-setup---hermes-agent-era
./git-setup config
```

También puedes añadir la raíz del repositorio a tu `PATH`.

## Comandos

```bash
git-setup config                         # genera ~/.config/git
git-setup setup                          # GitHub, SSH, GPG y firma Git
git-setup verify                         # audita la configuración completa
git-setup test                           # prueba commits y firma
git-setup clean                          # elimina la configuración creada
```

## Identidad y personalización

Evita prompts en instalaciones automatizadas con `NAME` y `EMAIL`:

```bash
NAME='Ada Lovelace' EMAIL='ada@example.com' git-setup config
```

`gitconfig.local` nunca se genera, actualiza ni elimina. Úsalo para valores
locales que deban sobrevivir una actualización de plantillas.

```bash
nvim ~/.config/git/gitconfig.local
```

`clean` solicita escribir `yes` antes de actuar.

## Seguridad

- El token de GitHub se lee sin eco y no se muestra en la salida.
- Las claves GPG nuevas usan el diálogo de frase de paso de GPG.
- Antes de usar `setup`, revisa los permisos y el alcance del token de GitHub.

## Desarrollo

Ejecuta las pruebas locales:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
```

ShellCheck y las pruebas se ejecutan también en GitHub Actions. Consulta
[CONTRIBUTING.md](CONTRIBUTING.md) para el flujo de contribución.

## Licencia

MIT. Consulta [LICENSE](LICENSE).
