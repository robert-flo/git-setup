# Especificación: modularizar `git-setup` alrededor de comandos ejecutables

## Problem Statement

`git-setup` ha crecido hasta mezclar varias responsabilidades en su entrypoint
principal: carga de dependencias, presentación, menú interactivo, resolución de
argumentos y ejecución de las operaciones de configuración.

Al mismo tiempo, los archivos de comandos deben conservar una propiedad
importante del diseño actual: cada operación debe poder invocarse directamente,
sin pasar por el menú. La modularización no debe convertir esos comandos en
funciones privadas ni eliminar sus interfaces ejecutables.

La estructura actual hace que un mantenedor tenga que reconstruir qué parte del
entrypoint carga cada comando, qué funciones quedan disponibles después de
sourcear módulos y qué camino toma una acción seleccionada desde el menú.

## Solution

Reorganizar `git-setup` alrededor de una interfaz común de comandos ejecutables.

El entrypoint principal será pequeño y se encargará de iniciar el runtime,
mostrar el menú y delegar. Un dispatcher separado resolverá los nombres y
aliases de los comandos, pero ejecutará los módulos de comandos como archivos
independientes.

Cada comando conservará dos formas equivalentes de uso:

1. Invocación directa desde la terminal.
2. Invocación desde el menú interactivo.

Ambas formas deben terminar ejecutando el mismo archivo de comando, con las
mismas entradas, salida y reglas de código de retorno. El menú no llamará
directamente funciones internas como `do_setup` o `run_test`.

La implementación privada —helpers, librerías, dispatcher y templates— debe
agruparse bajo una carpeta de runtime claramente diferenciada de la superficie
pública del repositorio. Los comandos seguirán siendo ejecutables dentro de
esa carpeta.

## User Stories

1. Como usuario, quiero ejecutar una operación directamente, para no depender
   del menú interactivo.
2. Como usuario, quiero ejecutar una operación desde el menú, para descubrir
   las capacidades de `git-setup` sin memorizar comandos.
3. Como usuario, quiero que la ejecución directa y la ejecución desde el menú
   produzcan el mismo resultado, para no tener que aprender dos interfaces.
4. Como usuario, quiero ejecutar `--help` en cada comando, para conocer sus
   precondiciones, opciones y efectos antes de modificar mi sistema.
5. Como usuario, quiero que `git-setup --help` funcione aunque falten
   dependencias operativas, para poder solucionar la instalación inicial.
6. Como usuario, quiero que un comando desconocido produzca un error claro,
   para corregir la invocación sin entrar accidentalmente al menú.
7. Como usuario, quiero conservar los nombres y aliases existentes, para no
   romper automatizaciones ni memoria muscular.
8. Como usuario, quiero que una operación fallida desde el menú no cierre el
   menú, para poder leer el diagnóstico y elegir otra acción.
9. Como usuario, quiero que una operación fallida invocada directamente
   conserve su código de salida, para poder usarla desde scripts de
   automatización.
10. Como mantenedor, quiero que cada comando tenga un entrypoint ejecutable
    autónomo, para probarlo y ejecutarlo sin conocer el estado interno del
    menú.
11. Como mantenedor, quiero que el dispatcher solo resuelva y delegue, para
    evitar duplicar la implementación de cada comando.
12. Como mantenedor, quiero que el menú no conozca funciones internas de los
    comandos, para poder cambiar una implementación sin editar la navegación.
13. Como mantenedor, quiero que las rutas de runtime, templates y configuración
    se calculen desde una única fuente, para evitar diferencias entre la
    invocación directa y la invocación desde el entrypoint.
14. Como mantenedor, quiero separar presentación, runtime, dependencias y
    dispatch, para localizar cambios y fallos con menor esfuerzo.
15. Como mantenedor, quiero que los comandos compartan helpers pequeños y
    explícitos, para reducir duplicación sin crear una librería global opaca.
16. Como mantenedor, quiero que el menú pueda obtener descripciones de los
    comandos desde una fuente declarativa, para que agregar una operación no
    requiera actualizar varias listas manualmente.
17. Como mantenedor, quiero preservar números, iconos y orden del menú, para
    no sacrificar la experiencia interactiva en favor del descubrimiento
    automático.
18. Como mantenedor, quiero ejecutar cada comando bajo tests aislados, para
    verificar comportamiento sin depender de GitHub, SSH, GPG o credenciales
    reales.
19. Como mantenedor, quiero sustituir binarios externos mediante mocks en
    `PATH`, para comprobar las invocaciones sin efectos externos.
20. Como mantenedor, quiero que las pruebas crucen el mismo seam que usan los
    usuarios, para evitar tests acoplados a funciones internas.
21. Como mantenedor, quiero conservar la posibilidad de ejecutar el runtime en
    Docker, para validar el comportamiento en una instalación limpia.
22. Como mantenedor, quiero que el layout del repositorio distinga la
    superficie pública de la implementación privada, para que un nuevo
    colaborador pueda orientarse sin reconstruir el sistema completo.
23. Como usuario de Bash o Zsh, quiero completion para los comandos y sus
    opciones, para descubrir la interfaz desde la terminal.
24. Como futuro agente de mantenimiento, quiero una especificación explícita
    del contrato de cada comando, para modularizar el repositorio sin cambiar
    su comportamiento reconocible.

## Implementation Decisions

- El seam principal será el proceso de comando ejecutable. Su interfaz incluye
  argumentos, variables de entorno, lectura desde `stdin`, salida humana y
  código de retorno.
- El entrypoint principal conservará el menú y la coordinación mínima del
  arranque. No cargará las implementaciones de los comandos para invocarlas
  como funciones.
- El dispatcher será una infraestructura privada. Resolverá nombres largos,
  aliases y opciones globales, validará que el módulo exista y ejecutará el
  archivo de comando correspondiente.
- El dispatcher debe pasar argumentos restantes al comando y propagar su
  código de retorno cuando la invocación sea directa.
- El menú invocará el dispatcher con el nombre canónico de cada acción. En modo
  interactivo, un error de acción se mostrará y el ciclo del menú continuará.
- Los módulos de comandos permanecerán ejecutables por sí mismos y conservarán
  su bootstrap independiente. No se eliminarán los entrypoints directos.
- Cada comando debe aceptar `-h` y `--help` antes de ejecutar efectos o exigir
  dependencias específicas de su operación.
- La ayuda global y las opciones globales se resolverán antes del chequeo de
  dependencias operativas. La ayuda no debe requerir GitHub CLI, GPG, SSH ni
  Delta para poder mostrarse.
- Las operaciones existentes se conservarán: configuración, verificación,
  setup, prueba de integración, limpieza y ayuda. No se cambiarán sus efectos
  funcionales como parte de esta modularización.
- Las funciones compartidas se separarán por capacidad: rutas y configuración,
  runtime y cleanup, presentación, dependencias y dispatch. La separación debe
  evitar que los comandos dependan de un archivo global que mezcle todas las
  responsabilidades.
- Las rutas del repositorio, runtime, templates, configuración generada y
  comandos workflow se calcularán desde una única configuración compartida.
- La implementación privada se agrupará bajo una carpeta de runtime que
  contenga helpers, librerías, comandos ejecutables y templates. Las carpetas
  de documentación, tests y la superficie de Make permanecerán distinguibles
  como superficies del proyecto.
- El menú puede usar un manifiesto declarativo para nombres canónicos,
  descripciones e iconos. El manifiesto no debe reemplazar la ayuda propia de
  cada comando ni convertir el orden del menú en un efecto accidental del orden
  de archivos.
- El manifiesto debe tener una única fuente de verdad para el menú y, cuando
  sea viable, para generar ayuda y completion.
- Para que Bash y Zsh compartan el mismo contrato sin que Zsh tenga que
  `source`ar código Bash, esa fuente será un archivo plano y neutral al
  lenguaje, `runtime/commands.tsv`, con un registro por comando. El loader de
  Bash, el completion de Zsh, el menú, la ayuda y el dispatcher leerán ese
  contrato; ningún loader de shell será la fuente exclusiva de la metadata.
- La solución no debe hacer obligatorio `fzf` para el menú principal ni copiar
  el modelo de repositorio Git bare de otros proyectos de dotfiles.
- La implementación debe preservar la compatibilidad de las invocaciones
  documentadas y de los aliases existentes, salvo que una futura especificación
  autorice explícitamente un cambio.
- La modularización debe ser incremental: primero separar el seam ejecutable,
  después ordenar helpers y runtime, y finalmente añadir manifiesto y
  completion.

## Testing Decisions

- Los tests deben observar comportamiento externo: código de salida, archivos
  generados o eliminados, mensajes esenciales, invocaciones a dependencias y
  continuidad del menú.
- No se deben probar directamente detalles como si una función concreta fue
  llamada o qué archivo interno contiene una función.
- El test principal de cada operación debe ejecutar su módulo como archivo
  independiente.
- Debe existir cobertura para la invocación directa y para la invocación por el
  dispatcher.
- Debe verificarse que el menú delega correctamente cada opción y continúa
  después de un fallo recuperable.
- Debe verificarse que la CLI conserva los códigos de salida de los comandos.
- Debe verificarse que `--help` y `--version`, si se mantienen o incorporan,
  funcionan antes de validar dependencias operativas.
- Debe verificarse que un comando desconocido no ejecuta el menú ni modifica
  configuración.
- Debe verificarse que los aliases existentes llegan al comando canónico
  correcto.
- Debe verificarse que los comandos directos calculan las mismas rutas que el
  entrypoint.
- Las dependencias externas deben reemplazarse mediante stubs controlados por
  `PATH`, siguiendo el patrón ya usado por los tests actuales del repositorio.
- Las pruebas deben permanecer offline y no tocar las credenciales reales del
  desarrollador.
- Se deben conservar y ampliar las pruebas de Docker para validar el payload
  reubicado y la ejecución del entrypoint en un entorno limpio.
- El criterio de aceptación final incluye `bash -n`, `shellcheck`, `shfmt`, la
  suite existente y los nuevos tests de comandos.
- La validación debe comprobar que no quedan scripts parcialmente cargados ni
  rutas antiguas en el entrypoint, dispatcher, Dockerfiles, documentación o
  tests.

## Out of Scope

- Cambiar el propósito de `git-setup` o convertirlo en un gestor general de
  dotfiles.
- Adoptar un repositorio Git bare, symlink management o GNU Stow como modelo
  interno.
- Hacer que `fzf` sea obligatorio para usar el menú o los comandos directos.
- Rediseñar visualmente el menú, sus iconos o su flujo de navegación más allá
  de lo necesario para delegar correctamente.
- Cambiar los efectos de setup, configuración, verificación, test o limpieza.
- Cambiar nombres de comandos o aliases existentes.
- Añadir nuevas operaciones de GitHub, SSH o GPG no relacionadas con la
  modularización.
- Reescribir los comandos en otro lenguaje o introducir un framework de CLI.
- Crear un modo genérico para operar repositorios Git arbitrarios.
- Automatizar todavía la publicación, merge o release de paquetes.
- Resolver mejoras de seguridad o portabilidad no necesarias para mantener el
  contrato actual; esas mejoras deben tener su propia especificación.

## Further Notes

- El diseño de referencia que motivó esta especificación usa un launcher
  pequeño, comandos ejecutables autónomos, helpers separados, configuración
  centralizada, ayuda por comando y tests con mocks de `PATH`.
- La decisión más importante es conservar la ejecución directa de los módulos.
  La agrupación del runtime no debe ocultar ni eliminar esa capacidad.
- El agente que implemente esta especificación debe inspeccionar primero los
  módulos actuales, sus tests, Dockerfiles, documentación y ADRs. Debe
  preservar el comportamiento antes de introducir mejoras incrementales.
- La primera entrega debe dejar un dispatcher funcional y equivalencia entre
  menú, CLI y ejecución directa. El manifiesto y completion pueden seguir en
  entregas posteriores si no son necesarios para cerrar ese seam.
- Antes de considerar completa la modularización, debe existir una explicación
  breve de la nueva topología para que un colaborador pueda identificar el
  entrypoint, el runtime, los comandos, los templates y los tests sin seguir
  cadenas de `source` manualmente.
