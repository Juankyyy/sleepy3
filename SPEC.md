# Sleepy3 — Especificación de producto y técnica

**Proyecto:** Sleepy3
**Plataforma:** Android
**Stack principal:** Flutter + Material 3 Expressive
**Estado:** migración a Flutter en curso; Home, Stats, Settings, la persistencia local y
Health Connect (Local/Google Health) ya funcionan. El widget de pantalla de inicio es lo
siguiente.

---

## 1. Flujo de trabajo y releases

### Ramas

- Todo el trabajo nuevo se hace en la rama **`dev`**. Cada push a `dev` publica
  automáticamente una **pre-release** de desarrollo.
- `main` permanece estable y se actualiza **solo con autorización explícita del usuario**,
  después de verificar el bloque o la funcionalidad en su máquina. El agente nunca hace
  merge ni push a `main` por iniciativa propia. Cada push autorizado a `main` publica
  automáticamente la **release estable** de la minor.
- El trabajo no se queda solo en local: cuando el usuario dice «Haz los commits», se
  commitea **y se sube a `dev`**.
- Los tags los crea el CI; no se crean a mano.

### Forma de trabajo

- **Paso a paso:** no generar toda la app de golpe. Esperar a que el usuario pida un módulo
  o cambio concreto. Al terminar, indicar qué debe probar el usuario.
- **Aviso previo:** el agente no commitea ni hace push por iniciativa propia. Propone el
  mensaje, espera el OK y recién entonces ejecuta. «Haz los commits» autoriza commit y push
  a `dev` (y con ello una pre-release), nunca tocar `main`.
- **Documentación como parte del cambio:** actualizar `SPEC.md` si cambia el comportamiento
  o la arquitectura, y `README.md` si el cambio es visible para el usuario.

### Idioma

- Código, comentarios, UI, mensajes de commit y notas de release: **inglés**.
- Documentación de trabajo (`SPEC.md`, `AGENTS.md`, `README.md`): puede estar en español,
  salvo que el usuario pida lo contrario.

### Commits

Commits convencionales, en inglés y con scope:

```text
feat(ui): add history summary
fix(data): restore an open session
docs(spec): define widget contract
refactor(core): extract duration formatter
test(ui): cover the 360dp layout
chore(repo): ignore local release notes
ci(release): publish the APK
```

### Releases

#### Canales y versiones

| Canal | Disparador | Versión | Título inicial | GitHub |
|---|---|---|---|---|
| `dev` | push | `v0.X.Y` (sube el parche) | `v0.X.Y` | Pre-release |
| `main` | push | `v0.X.0` (sube la minor) | `v0.X.0` | Latest |

- La siguiente versión sale del tag semver más alto del repositorio. En `dev` se
  incrementa el parche; en `main`, la minor, y el parche vuelve a cero.
- Primera release de desarrollo: `v0.0.1`. Primera release estable: `v0.1.0`. Después de
  `v0.1.0`, `dev` publica `v0.1.1`, `v0.1.2`…; el siguiente push a `main` publica `v0.2.0`.
- El `versionCode` de Android es `major * 1.000.000 + minor * 1.000 + patch`
  (`v0.0.1` → 1, `v0.1.0` → 1000, `v0.2.0` → 2000). Es monótono entre canales.
- `pubspec.yaml` no lleva la versión de la release. El workflow pasa la versión y el code
  calculados a `flutter build apk`; los builds locales siguen usando el valor del
  `pubspec`.
- Reintentar el workflow es idempotente: si un tag del mismo canal ya apunta al commit, se
  reutiliza y solo se refrescan los assets; no se duplican releases ni se sobrescriben
  títulos o notas ya curados.

#### Notas y títulos

- Las releases de `dev` llevan notas generadas desde los commits convencionales, agrupadas
  en `## ✨ Features`, `## 🐛 Fixes`, `## ⚡ Performance` y `## 🔧 Maintenance`. Solo se
  emiten las secciones con commits, más un enlace de changelog completo. El título es el
  tag, sin tema.
- Las releases de `main` se publican con esas mismas notas generadas desde el `vX.Y.0`
  anterior (cubren toda la minor) y un título `vX.Y.0`. Después se reemplazan por las notas
  curadas y el título con tema.
- Formato del título curado: `vX.Y.Z - The <Tema> Update`, donde `<Tema>` resume en inglés
  lo más importante (Title Case; siempre termina en `Update`).
- Las notas curadas no viven en el repo: `release-notes/` está en `.gitignore`. La primera
  línea de `release-notes/vX.Y.0.md` lleva el título:

```html
<!-- title: v0.1.0 - The Quiet Night Update -->
```

- Después de publicar `main`, aplicar notas y título con:

```bash
dart run tool/apply_release_notes.dart v0.1.0
```

  El script lee el título de la primera línea y ejecuta `gh release edit`; no toca el APK.
- Estilo de las notas curadas: inglés, emojis en los títulos de sección, contexto breve, una
  sección destacada y `## ✨ What's new` con el resto. Instalación, datos, requisitos y
  actualización viven en el `README.md`, no en las notas.
- El cuerpo publicado en GitHub debe coincidir con `release-notes/vX.Y.0.md`.

#### APK y firma

- El workflow compila un APK universal firmado con el keystore de release y adjunta
  `sleepy3-vX.Y.Z.apk` y su `.sha256`.
- Secrets del repo: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD`. Si falta alguno, el workflow falla; nunca
  publica un APK firmado con debug.
- El keystore se guarda fuera del repo y se conserva: si se pierde, no se pueden publicar
  actualizaciones de la app ya instalada.
- En local, sin `android/key.properties`, los builds de release usan la firma de debug.

#### Si el workflow falla

- Reintentar desde Actions o con `workflow_dispatch`. El APK también queda como artifact
  del run.
- La versión se recalcula de forma idempotente; no se publican releases duplicadas.
- Si un push a `main` falla, no se crea el tag ni la release: se corrige y se vuelve a
  lanzar.

---

## 2. Producto

Sleepy3 es una app Android de registro de sueño con fricción cero.

- Dos acciones grandes: **Sleep** y **Wake**. Sin formularios, sin cuentas, sin onboarding
  obligatorio.
- Guarda la hora exacta de inicio y fin de cada sesión.
- Los datos son locales por defecto. No hay backend ni nube propia.
- Health Connect es opcional: el usuario elige `Local` o `Google Health` como fuente de
  datos, y puede copiar sesiones entre ambos.
- Un widget de pantalla de inicio permitirá registrar Sleep/Wake sin abrir la app.

### Objetivo de diseño

Que registrar el sueño lleve menos de dos segundos y no requiera pensar. La app debe
funcionar bien de noche, con una sola mano y con el teléfono bloqueado o desbloqueado.

### Fuera de alcance por ahora

- Cuentas, login, sincronización propia en la nube.
- UI para tablets o wearables.
- Edición manual avanzada del historial.
- Notificaciones o alarmas inteligentes.

---

## 3. Requisitos funcionales

### 3.1 Máquina de estados Sleep/Wake

| Estado | Sleep | Wake | Línea de sesión |
|---|---|---|---|
| Despierto, sin sesión previa, de día | Habilitado | Deshabilitado | `No active session` |
| Despierto, sin sesión previa, de noche | Habilitado | Deshabilitado | `Tap Sleep when you turn off the lights` |
| Durmiendo | Deshabilitado | Habilitado | `Sleeping since HH:MM` |
| Despierto, con sesión previa | Habilitado | Deshabilitado | `Last session: 7h 45m` |

Reglas:

- Un toque en **Sleep** abre una sesión con la hora actual y la persiste.
- Un toque en **Wake** cierra la sesión abierta, calcula la duración y la persiste.
- Si ya hay una sesión abierta, Sleep no hace nada.
- Si no hay sesión abierta, Wake no hace nada.
- Una sesión cerrada con una hora anterior al inicio se recorta a duración cero.
- Al arrancar la app se restaura la sesión abierta; las sesiones cerradas se cargan de la
  fuente elegida (ver 3.6), ordenadas de más antigua a más reciente. Home filtra los
  últimos 3 días para su resumen y `Stats` filtra el rango elegido.
- Las escrituras a disco se serializan: un Wake inmediatamente después de Sleep no puede
  adelantarse al inicio.
- El día va de 07:00 a 18:59 y la noche de 19:00 a 06:59, en hora local. Es una regla
  del prototipo, no de M3. La sesión anterior tiene prioridad sobre el copy de día/noche.

#### 3.1.1 Cabecera y reloj

- La cabecera muestra `Sleepy3` y un chip de estado: `Day · ready to wake` o
  `Night · time to rest`.
- El reloj muestra la hora local con segundos. Sigue el formato 12/24 h del sistema; en
  12 h muestra `AM`/`PM`.
- La fecha se muestra bajo el reloj, por ejemplo `Tuesday, October 20`.
- El reloj se actualiza cada segundo. El temporizador se pausa cuando la app pasa a
  segundo plano y el reloj se refresca al volver al primer plano.
- El reloj usa `sleepClockProvider`, igual que la máquina de estados, para que los tests
  puedan avanzar el tiempo.

#### 3.1.2 Resumen de 3 días

- La tarjeta de Home muestra solo sesiones cerradas, agrupadas por el día local en que
  se despertó: hoy, ayer y anteayer.
- Una sesión completa pertenece al día de `endedAt`, aunque haya empezado antes de
  medianoche. Si hay varias sesiones el mismo día, sus duraciones se suman.
- Home recibe todo el historial cerrado y descarta en memoria las sesiones fuera de la
  ventana antes de agrupar.
- La media divide por los días con datos, no por 3. Un día sin sesión no baja la media.
- Cada barra compara el día con una meta de 8 h y se recorta al 100 %. Sin datos, la barra
  queda a cero. La meta de 8 h es una decisión de producto, no un token M3.
- Sin datos se muestra `—` en la media y en cada día.
- El resumen se recalcula con el reloj inyectado: al cambiar la fecha local, hoy pasa a
  ayer sin reiniciar la app.
- Los días se calculan con aritmética de calendario, no restando 24 h, para que un cambio
  de horario (DST) no desplace ni mezcle los grupos.

### 3.2 Navegación

- Barra de navegación M3 flexible (`M3ENavigationBar`, 64 dp) con tres destinos de
  igual importancia: `Home`, `Stats` y `Settings`.
- `Home` es el destino inicial. `Stats` muestra el resumen por rango y el historial;
  `Settings` contiene apariencia, la fuente de datos, el estado de Google Health y la
  información de la app.
- El destino activo usa icono relleno, etiqueta en negrita y la píldora de selección;
  los inactivos usan icono outline.
- Un `IndexedStack` conserva el estado de cada pestaña al cambiar de destino, incluido
  el rango elegido en `Stats` durante la sesión de la app. El rango no se persiste entre
  arranques.
- Atrás desde `Stats` o `Settings` vuelve a `Home`; atrás desde `Home` sale de la app.

### 3.3 Stats e historial

- `Stats` tiene tres filtros de rango: `7 days`, `30 days` y `All`. Son filter chips M3
  de selección única; por defecto se abre en `7 days`.
- La ventana de 7 días incluye hoy y los seis días locales anteriores. La de 30 días
  incluye hoy y los veintinueve anteriores. `All` incluye todo el historial cerrado hasta
  hoy. Las sesiones que terminan después de hoy no se muestran.
- La tarjeta de resumen muestra la media de los días con datos, el número de noches y el
  total del rango. Si no hay noches en el rango muestra `—`, `No nights in this range` y,
  cuando existe historial más antiguo, un botón `Show all` que cambia el filtro a `All`.
- En modo `Google Health`, elegir `All` pide el permiso de historial de Health Connect. Si
  ya estaba concedido, no se vuelve a preguntar. Si se deniega, el rango sigue siendo
  `All`, pero la lectura se limita a los últimos 30 días; un banner explica el límite y
  ofrece `Allow full history`, que vuelve a pedir el permiso y recarga el historial. Los
  rangos `7 days` y `30 days` no piden nada. Al volver del segundo plano se relee el
  permiso por si el usuario lo cambió en Health Connect.
- Debajo, una sola lista muestra una fila por sesión cerrada, de la más reciente a la
  más antigua. Cada fila tiene tres líneas: el día de despertar como overline
  (`Today`, `Yesterday`, `Tue, Oct 20` o con año si no es el año actual), la duración
  como headline y `inicio – fin` como supporting text.
- Las sesiones no se agrupan en una fila por día: si hubo varias el mismo día, cada una
  conserva su propia fila. La media y el total sí agrupan por día de despertar, con la
  misma regla que Home (3.1.2).
- Las sesiones abiertas no entran en la media, el total ni la lista. Si hay una abierta,
  la cabecera lo explica con `Sleeping since {time} · it will appear when you wake.`
- Sin ninguna sesión cerrada se muestra un empty state. El texto cambia si hay una sesión
  abierta para explicar que la primera noche aparecerá al despertar.
- La fecha y la ventana se recalculan a medianoche local y al volver del segundo plano
  con `LocalDayBuilder`, no con un reloj que reconstruye cada segundo. Los días se
  calculan con aritmética de calendario para no desplazar los grupos con DST.
- Esta primera versión no tiene gráfico ni detalle de sesión. La lista no es editable y
  sus filas no son interactivas; el lector de pantalla anuncia día, duración y rango de
  horas como una sola etiqueta.

### 3.4 Settings

- La pantalla tiene cabecera `Settings` y línea de apoyo `Theme, sleep data and app info.`,
  seguida de cuatro secciones: `Appearance`, `Sleep data`, `Google Health` y `About`.
- Cada sección usa un encabezado `titleMedium` emphasized y una lista agrupada
  `M3EList`/`M3EListItem` con radio exterior 16 dp, interior 4 dp y gap 2 dp.
- `Appearance` contiene una fila `Theme` cuyo supporting text muestra el modo actual:
  `System`, `Light` o `Dark`. Al tocarla se abre un diálogo M3 de selección con opciones
  de radio y acciones `Cancel` / `Apply`. `Apply` aplica y persiste el modo; `Cancel`
  no cambia nada. El valor por defecto es `System`.
- `Sleep data` contiene:
  - `Source`, cuyo supporting text muestra `Local` o `Google Health`. Al tocarla se abre
    el diálogo `Sleep data source` con una fila de radio por fuente y `Cancel` / `Apply`.
    Al elegir `Google Health` se comprueba la disponibilidad y se piden `READ_SLEEP` y
    `WRITE_SLEEP`; si no está disponible, hay que actualizar Health Connect o se deniega
    el permiso, la fuente se queda en `Local` y un snackbar explica el motivo. Volver a
    `Local` guarda y recarga, pero no revoca permisos.
  - `Import` con apoyo `Download from Google Health to the local copy.`. Ejecuta la
    descarga de todas las sesiones de Health Connect. Pide el permiso de historial antes
    de descargar; si se deniega, baja solo los últimos 30 días y el resultado lo indica.
- La sección `Google Health` se muestra en ambos modos: el estado de conexión y las
  acciones de copia no dependen de la fuente activa.
- `Google Health` contiene:
  - `Status`, con `Checking…`, `Connected`, `Connected · {n} pending`,
    `Connected · Last sync {time}`, `Permission needed`, `Not available` o
    `Update required`. `Permission needed` añade una fila `Connect`; `Not available` y
    `Update required` añaden `Install`.
  - `Sync` con apoyo `Send the most recent local session.` y `Add` con apoyo
    `Send local sessions that aren't in Google Health.`. Ambas acciones están disponibles
    tanto en `Local` como en `Google Health` y nunca cambian la fuente mostrada.
- Las tres acciones de copia (`Import`, `Sync`, `Add`) piden permiso al pulsarlas si
  falta. Muestran un diálogo de confirmación, un diálogo de progreso no descartable y un
  diálogo de resultado con el recuento de añadidas, actualizadas, omitidas y fallidas.
  `Sync` y `Add` solo envían filas `origin='local'` pendientes; `Import` añade o actualiza
  filas descargadas y nunca sobrescribe una fila local. Repetir una acción no duplica.
- El primer cambio a `Google Health` con sesiones locales pendientes muestra el diálogo
  opcional `Copy local sessions?` con `Sync`, `Add` y `Not now`. Los botones de copia
  siguen disponibles después en la sección `Google Health`.
- `About` contiene `Privacy` con apoyo `On-device only.` en `Local` o
  `Stored in Health Connect. Google Health can read it.` en `Google Health`, `Version`
  con `{version} ({build})` cuando el plugin de información de la app responde (la fila se
  oculta si no hay dato) y `Licenses`, que abre la página de licencias de Flutter con el
  nombre, la versión y la leyenda GPLv3.
- El modo de tema y la fuente de datos se guardan en la tabla `preferences` de la misma
  base Drift; no se usa `shared_preferences`.

### 3.5 Widget de pantalla de inicio (planificado)

- Dos acciones: **Sleep** y **Wake**.
- El toque registra la hora sin abrir la app.
- Los eventos se escriben en una cola de pendientes.
- La app reconcilia la cola al abrirse o volver al primer plano.
- El widget refleja el estado actual (despierto/durmiendo) con los roles del tema M3.

### 3.6 Health Connect y Google Health

- La fuente de datos es `Local` (por defecto) o `Google Health`. Nunca se mezclan: `Local`
  lee solo Drift y `Google Health` lee solo Health Connect.
- En `Local`, Health Connect no se lee ni se escribe automáticamente. En `Google Health`,
  Home y Stats leen todas las sesiones `SLEEP_SESSION` de Health Connect, vengan de la app
  que vengan.
- `Sleep` y `Wake` siempre escriben la fila local como copia de seguridad. En `Google
  Health`, `Wake` escribe además en Health Connect con un `clientRecordId` estable; si
  falla, la fila queda pendiente, Home y Stats muestran `{n} sessions waiting to sync` con
  `Retry`, y el reintento ocurre al abrir o volver a la app. Una sesión pendiente no entra
  en las gráficas de Google Health hasta que se confirma la escritura.
- Las sesiones de duración cero se marcan como omitidas y no se suben ni se reintentan.
- Las acciones de copia son explícitas y no cambian la fuente: `Sync` sube la sesión local
  pendiente más reciente, `Add` sube todas las pendientes de la más antigua a la más
  reciente e `Import` descarga todas las sesiones de Health Connect a la copia local.
- La descarga deduplica por UUID y, si falta, por inicio y fin exactos. Inserta las nuevas
  con `origin='healthConnect'`, actualiza las descargadas que cambiaron y nunca sobrescribe
  ni borra filas `origin='local'`. Las descargadas no se vuelven a subir.
- Los permisos se piden al usar la función, no en el primer arranque. Si Health Connect no
  está disponible o el permiso se deniega, la app sigue funcionando localmente.
- Sleepy3 lee y escribe en Health Connect, no en la nube de Google Health. Un registro que
  solo esté en la nube aparece cuando Google Health lo sincroniza con Health Connect.
- El historial completo (más de 30 días) requiere `READ_HEALTH_DATA_HISTORY`. Sleepy3 lo
  pide al elegir `All` en Stats o al usar `Import`; si se deniega, aplica un límite de 30
  días por su cuenta. Stats muestra el banner `Only the last 30 days are available` con
  `Allow full history`, e `Import` añade al resultado `Only the last 30 days were
  downloaded.`. El permiso se relee al cargar el historial y al volver del segundo plano,
  así que una concesión hecha en Health Connect se aplica sin reiniciar la app.

### 3.7 Accesibilidad

- Objetivo táctil mínimo de 48 × 48 dp.
- Etiquetas visibles y descripciones accesibles.
- Foco visible en botones.
- Respetar el tamaño de texto del sistema; si no caben dos botones lado a lado, apilarlos.
- Respetar la preferencia de movimiento reducido cuando se agreguen animaciones.

---

## 4. UX y diseño visual

- Material Design 3 Expressive con **tema fijo**. Sin color dinámico (Material You).
- Esquema claro y oscuro generados por separado desde la misma semilla azul Sleepy3
  (`#2B3A8F`). El oscuro no se deriva del `primary` del claro.
- El modo sigue al sistema por defecto. Desde `Settings` se puede fijar `System`,
  `Light` o `Dark`; la elección se aplica al instante y se conserva entre arranques.
- Tipografía **Roboto Flex variable** empaquetada como asset (`assets/fonts/`, OFL).
  Se usan los tamaños, pesos y tracking de la escala M3; no se usan pesos 850/950.
- Mapeo tipográfico:
  - reloj: `displayLarge` emphasized, con cifras tabulares;
  - AM/PM: `titleMedium`;
  - marca: `headlineLarge` emphasized;
  - fecha y copy de apoyo: `bodyMedium` (la línea de sesión, emphasized);
  - chip día/noche: `labelMedium`;
  - cabecera y tarjeta de resumen de Home: `titleMedium` y `labelMedium` (la tarjeta no
    necesita `bodyMedium`).
- La ilustración de luna/sol del prototipo no forma parte de la UI.
- Navegación:
  - Barra M3 flexible de 64 dp, a todo el ancho, con `surfaceContainer` y sin borde
    ni sombra.
  - Tres destinos: `Home`, `Stats` y `Settings`. El activo usa la píldora de selección
    y un icono relleno; los inactivos, icono outline.
  - `Stats` y `Settings` tienen contenido (ver abajo).
- Pantalla principal:
  - Cabecera centrada: `Sleepy3` en `headlineLarge` emphasized y un chip de estado
    (`Day · ready to wake` / `Night · time to rest`) en `labelMedium`. El chip no es un
    componente M3: es una etiqueta de estado construida con los roles y la forma full
    de M3.
  - Reloj en vivo en `displayLarge` emphasized, con segundos, cifras tabulares y
    `AM`/`PM` en `titleMedium` cuando el sistema usa 12 h.
  - Fecha en `bodyMedium` y línea de sesión en `bodyMedium` emphasized.
  - El reloj es una línea única. Si el tamaño de texto del sistema no cabe en el ancho,
    solo el reloj se reduce; el resto del texto respeta la escala del sistema.
  - Dos `M3EButton.icon` XL de 136 dp de alto, forma square (radio 28 dp), estilo
    `filled`, icono leading de 40 dp y etiqueta `labelLarge`. Ambos usan
    `primary`/`onPrimary`; el deshabilitado usa los tokens disabled del botón M3E.
    La etiqueta `labelLarge` y el padding horizontal de 16 dp son decisiones de layout
    para que quepan dos botones en 360 dp, no tokens M3: M3 Expressive asigna al botón XL
    un rol tipográfico mayor y 64 dp de padding lateral.
  - En pantallas angostas o con texto grande, los botones se apilan.
  - Tarjeta de resumen `M3ECard` outlined (radio 12 dp, padding 16 dp):
    - título `Last 3 days · {avg} avg` en `titleMedium` emphasized;
    - tres columnas `Today` / `Yesterday` / `2 days ago` con etiquetas
      `labelMedium` y valores `titleMedium` con cifras tabulares;
    - barras de 4 dp con `primary` sobre `surfaceContainerHighest` y forma full.
      No son un componente M3: son una visualización de datos construida con roles y
      formas M3. La altura de 4 dp y la meta de 8 h son decisiones de producto/layout,
      no tokens M3;
    - sin datos, la media y los días muestran `—` y las barras quedan a cero.
- Pantalla Stats:
  - Título `Stats` en `headlineMedium` emphasized y línea de apoyo en `bodyMedium`;
    márgenes laterales de 16 dp, y 24 dp desde 600 dp de ancho (decisión de layout, no
    token M3).
  - Filtros `7 days` / `30 days` / `All` con `M3EChip` tipo filter: 32 dp de alto, radio
    8 dp y 8 dp entre chips. El activo añade un check leading, además del color, para no
    depender solo del color.
  - Tarjeta de resumen `M3ECard` outlined (radio 12 dp, padding 16 dp): etiqueta
    `Average sleep` en `labelMedium`, valor en `displaySmall` emphasized con cifras
    tabulares, apoyo en `bodyMedium` y `Show all` como botón de texto.
  - Encabezado de lista `History` en `titleMedium` emphasized.
  - Lista `M3EList`/`M3EListItem` no interactiva con radio exterior 16 dp, interior 4 dp y
    gap 2 dp. Cada fila usa overline `labelMedium`, headline `titleMedium` y supporting
    text `bodyMedium`; las filas crecen con el texto del sistema.
  - Sin datos, el empty state reutiliza `Sleepy3EmptyState` con icono, headline y apoyo.
- Pantalla Settings:
  - Título `Settings` en `headlineMedium` emphasized y apoyo en `bodyMedium`; márgenes
    laterales de 16 dp, y 24 dp desde 600 dp de ancho (decisión de layout).
  - Secciones `Appearance`, `Sleep data`, `Google Health` y `About` con encabezado
    `titleMedium` emphasized y 8 dp hasta la lista.
  - Filas `M3EListItem` dentro de `M3EList` con radio exterior 16 dp, interior 4 dp y gap
    2 dp. Las filas crecen con el texto del sistema.
  - La fila `Theme` usa el supporting text para el valor actual (`System`, `Light` o
    `Dark`), de modo que el lector de pantalla lo anuncie como parte de la etiqueta. El
    diálogo de selección usa opciones cortas para caber al 200 % de texto.
  - `Sleep data` muestra `Source` con el valor actual y `Import` para bajar todas las
    sesiones de Health Connect. El diálogo de fuente usa filas de radio a ancho completo
    para que `Google Health` no se recorte en pantallas angostas.
  - `Google Health` muestra `Status` y, si hace falta, `Connect` o `Install`. Debajo,
    `Sync` y `Add` son acciones de copia, no de conexión. Las tres acciones de copia
    (incluida `Import`) usan diálogos M3E de confirmación, progreso y resultado.
  - El progreso no se puede descartar mientras la copia está en curso. El resultado
    distingue añadidas, actualizadas, omitidas y fallidas, y no promete éxito parcial.
  - `About` muestra `Privacy` con el texto que corresponde a la fuente (`On-device only.`
    o `Stored in Health Connect. Google Health can read it.`), `Version` con el dato de
    `package_info_plus` como supporting text (se oculta si no está disponible) y
    `Licenses`, que abre `showLicensePage` (API estándar de Flutter, no un componente
    M3E).
  - Al 200 % de texto las etiquetas y los supporting text caben sin elipsis; la pantalla
    se desplaza verticalmente.
- Copy de la interfaz en inglés:

| Elemento | Texto |
|---|---|
| Acción de dormir | `Sleep` |
| Acción de despertar | `Wake` |
| Sin sesión, de día | `No active session` |
| Sin sesión, de noche | `Tap Sleep when you turn off the lights` |
| Chip de día | `Day · ready to wake` |
| Chip de noche | `Night · time to rest` |
| Durmiendo | `Sleeping since {time}` |
| Sesión anterior | `Last session: {duration}` |
| Resumen de 3 días | `Last 3 days · {avg} avg` |
| Día de hoy | `Today` |
| Día de ayer | `Yesterday` |
| Hace dos días | `2 days ago` |
| Resumen sin datos | `—` |
| Destinos de navegación | `Home`, `Stats`, `Settings` |
| Título de Stats | `Stats` |
| Apoyo de Stats | `Your sleep, night by night.` |
| Durmiendo en Stats | `Sleeping since {time} · it will appear when you wake.` |
| Filtros de Stats | `7 days`, `30 days`, `All` |
| Resumen de Stats | `Average sleep` |
| Sin noches en el rango | `No nights in this range` |
| Mostrar todo el historial | `Show all` |
| Límite de historial en Stats | `Only the last 30 days are available` / `Allow full history in Google Health to see older sessions.` / `Allow full history` |
| Historial denegado desde el banner | `Google Health needs permission to read older sleep sessions.` |
| Descarga limitada al historial | `Only the last 30 days were downloaded.` |
| Encabezado de la lista | `History` |
| Stats sin historial | `No sleep history yet` |
| Apoyo sin historial | `Your nights will appear here after you wake up.` |
| Apoyo sin historial durmiendo | `Your first night will appear here when you wake up.` |
| Título de Settings | `Settings` |
| Apoyo de Settings | `Theme, sleep data and app info.` |
| Secciones de Settings | `Appearance`, `Sleep data`, `Google Health`, `About` |
| Fila de tema | `Theme` |
| Modos de tema | `System`, `Light`, `Dark` |
| Fila de fuente | `Source` |
| Fuentes de datos | `Local`, `Google Health` |
| Diálogo de fuente | `Sleep data source`, `Cancel`, `Apply` |
| Fila de descarga | `Import` / `Download from Google Health to the local copy.` |
| Estado de Google Health | `Status` |
| Estados de conexión | `Checking…`, `Connected`, `Permission needed`, `Not available`, `Update required` |
| Acciones de conexión | `Connect`, `Install` |
| Acciones de copia | `Sync`, `Add`, `Import` |
| Diálogos de copia | `Sync last session?`, `Add all previous sessions?`, `Download from Google Health?` |
| Botones de copia | `Cancel`, `Sync`, `Add all`, `Download all`, `Close` |
| Primer cambio a Google Health | `Copy local sessions?` / `Sync`, `Add`, `Not now` |
| Privacidad en Local | `Privacy` / `On-device only.` |
| Privacidad en Google Health | `Privacy` / `Stored in Health Connect. Google Health can read it.` |
| Otras filas de About | `Version`, `Licenses` |
| Acciones del diálogo de tema | `Cancel`, `Apply` |

- No usar formularios, diálogos de confirmación ni pasos extra para registrar.
- La app no debe depender de gestos ocultos.

---

## 5. Stack técnico

| Capa | Tecnología |
|---|---|
| UI | Flutter 3.47.x / Dart 3.13.x |
| Diseño | `material_ui` 1.7.0 + `material_3_expressive` 1.1.7 |
| Tipografía | Roboto Flex variable, asset OFL (`assets/fonts/`) |
| Fechas | `intl` 0.20 |
| Estado | Riverpod |
| Persistencia | Drift + SQLite (`drift_flutter`, `sqlite3`) |
| Info de la app | `package_info_plus` 10.x |
| Widget | `home_widget` + Jetpack Glance nativo |
| Salud | `health` 13.x sobre Health Connect `SleepSessionRecord` |
| Background | WorkManager para Flutter |
| Android | `minSdk` 28, `applicationId` `com.sleepy3.app` |

Notas:

- `material_ui` está fijado en **1.7.0**: la 1.8.0 introduce `RoundedPolygon`, que choca con
  `material_new_shapes` usado por `material_3_expressive` 1.1.7. No actualizar hasta que
  los paquetes sean compatibles.
- No importar `package:flutter/material.dart` en el código de la app; usar
  `package:material_ui/material_ui.dart` y los componentes `M3E*`.
- No se requiere Android Studio. Flutter CLI + Android command-line tools alcanzan.
- Hot reload: `flutter run`, luego `r`.
- Los builds debug usan `applicationId` `com.sleepy3.app.debug`, etiqueta `Sleepy3 Debug` y
  sufijo de versión `-debug`, para convivir con la release firmada. Cada variante mantiene
  su propia base de datos local.

---

## 6. Arquitectura

```text
lib/
├── main.dart
├── app/
│   ├── sleepy3_app.dart
│   ├── sleepy3_shell.dart
│   └── navigation/
│       └── sleepy3_destination.dart
├── core/
│   ├── theme/
│   ├── time/             # clock formatting, day/night rule and LocalDayBuilder
│   └── widgets/
└── features/
    ├── sleep_tracking/
    │   ├── domain/
    │   ├── data/
    │   ├── application/
    │   └── presentation/   # home screen, header, clock, buttons and summary
    ├── stats/
    │   └── presentation/   # screen, range chips, summary and history list
    ├── settings/
    │   ├── domain/         # theme mode, app version and settings store contract
    │   ├── data/           # Drift-backed settings store
    │   ├── application/    # theme controller and providers
    │   └── presentation/   # settings screen, theme dialog and about list
    ├── health/
    │   ├── domain/         # gateway, source, history access, sync store and stored session
    │   ├── data/           # Health Connect gateway and Drift sync store
    │   ├── application/    # source, history, history-permission, sync, upload and copy
    │   └── presentation/   # copy dialogs, sync and history banners, source text
    └── widget/             # planificado
```

### Arranque

1. `main()` inicializa Flutter.
2. Abre `Sleepy3Database`.
3. Carga un `SleepSnapshot` con la sesión abierta y todas las sesiones cerradas,
   ordenadas de más antigua a más reciente.
4. Carga el modo de tema y la fuente de datos de `preferences`, y la versión instalada con
   `package_info_plus`.
5. Inyecta los stores, el snapshot, el tema inicial, la fuente y la versión en
   `ProviderScope`.
6. Recién entonces muestra la app.

Si una lectura inicial falla, la app arranca con el valor por defecto (estado vacío,
tema `System` o versión oculta) y registra el error; no debe quedar bloqueada en el
splash.

### Estado

- `SleepTrackingController` es un `Notifier<SleepTrackingState>`.
- Actualiza el estado en memoria primero, para que los botones respondan al instante.
- Después encola la escritura en un `Future` serializado.
- La UI escucha el estado; no lee la base de datos directamente.
- El reloj se inyecta con `sleepClockProvider`; la lógica de dominio no llama a
  `DateTime.now()`.
- `SleepTrackingController` siempre escribe la fila local y carga `closedSessions` desde
  la fuente elegida mediante `SleepHistoryRepository`. `historyStatus` y `historyError`
  cubren carga y error; al cambiar de fuente se vacía la lista visible antes de recargar.
- `SleepDataSourceController` valida disponibilidad y permisos antes de guardar
  `Google Health`; si falla, conserva `Local`.
- `HealthSyncController` mantiene el estado de conexión, la cola de pendientes y el
  último sync. `SleepCopyController` expone las tres acciones de copia y comparte el
  servicio con la UI. `HealthHistoryPermissionController` posee el permiso de historial
  (`unknown`, `authorized`, `denied`), comparte una sola petición concurrente y relee el
  estado al cargar el historial y al volver al primer plano.
- `ThemeModeController` es un `Notifier<AppThemeMode>`. Actualiza el estado al instante,
  serializa las escrituras y conserva la elección visible si una escritura falla.
- `Sleepy3App` resuelve el brillo con el modo de tema y el brillo del sistema; mantiene
  `M3EMaterialApp.autoTheming` desactivado para usar los esquemas claro/oscuro propios.

### Datos

- `SleepSessionStore` es la interfaz de persistencia.
- `DriftSleepSessionStore` es la implementación. Una sola consulta ordenada carga la
  sesión abierta y todo el historial cerrado; `SleepSnapshot.lastSession` es un getter.
- `SleepTrackingState` mantiene `closedSessions` completo de la fuente elegida. Home
  filtra los 3 días y `Stats` el rango elegido en memoria; la base de datos no se consulta
  desde la UI.
- `SleepHistoryRepository` tiene dos implementaciones: `LocalSleepHistoryRepository`
  (Drift) y `HealthConnectSleepHistoryRepository` (Health Connect). La segunda lee desde
  el epoch solo con `HealthHistoryAccess.authorized`; en caso contrario aplica
  `healthConnectHistoryLimit` (30 días) e incluye hasta el día siguiente para tolerar
  relojes desfasados.
- `HealthSyncStore` y `DriftHealthSyncStore` gestionan pendientes, UUID descargados y
  deduplicación sobre la misma base.
- `SettingsStore` es la interfaz de preferencias y `DriftSettingsStore` su implementación.
  Usa la tabla `preferences` de la misma base; no hay `shared_preferences`.
- Los tests usan `FakeSleepSessionStore`, `FakeSettingsStore`, `FakeHealthConnectGateway`,
  `FakeHealthSyncStore` o una base Drift en memoria.

### Widget y Health Connect

- El widget no ejecuta Flutter. Escribe eventos en una cola nativa/compartida.
- La app reconcilia esos eventos al arrancar o volver al primer plano.
- Health Connect se ejecuta desde Flutter y/o el layer nativo cuando corresponda.
- Ambas integraciones deben quedar detrás de interfaces pequeñas y documentadas.

---

## 7. Datos y persistencia

### Tabla `sleep_sessions`

| Columna | Tipo | Notas |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `started_at_millis` | INTEGER | Unix milliseconds, obligatorio |
| `ended_at_millis` | INTEGER | Unix milliseconds, nullable |
| `health_record_id` | TEXT | UUID de Health Connect; único cuando no es null |
| `health_synced_at_millis` | INTEGER | Última subida o descarga correcta |
| `health_sync_skipped` | INTEGER | 0/1; sesión no elegible (por ejemplo, duración cero) |
| `origin` | TEXT | `local` o `healthConnect`; por defecto `local` |

- `schemaVersion = 3`.
- Base: `sleepy3.sqlite` en el directorio de documentos de la app.
- La migración v2 → v3 añade las cuatro columnas con defaults y el índice único de
  `health_record_id`; las filas existentes quedan locales, pendientes y elegibles.
- El resumen de 3 días no añade columnas ni migración: consulta las cerradas con
  `ended_at_millis` entre el inicio local de hace 2 días y el inicio local de mañana.
- Al agregar o cambiar columnas, subir `schemaVersion` y escribir una migración.
- El código generado (`sleepy3_database.g.dart`) se commitea.
- Después de cambiar el esquema:

```bash
dart run build_runner build
```

### Tabla `preferences`

| Columna | Tipo | Notas |
|---|---|---|
| `setting_key` | TEXT | PRIMARY KEY |
| `setting_value` | TEXT | Valor serializado como texto |

- Clave `theme_mode` con valores `system`, `light` o `dark`; un valor ausente o
  desconocido se interpreta como `system`.
- Clave `sleep_data_source` con valores `local` o `healthConnect`; un valor ausente o
  desconocido se interpreta como `local`.
- La migración de v1 a v2 crea `preferences`; las sesiones existentes no se tocan.
- El modo de tema y la fuente se guardan en la misma base para no abrir un segundo
  almacén.

### Invariantes

- Como máximo una sesión abierta.
- `Wake` cierra todas las filas abiertas; si hubo un crash y quedaron duplicadas, se
  reparan.
- Una sesión abierta sobrevive al cierre de la app.
- La duración nunca es negativa.
- Los timestamps se guardan en milisegundos para conservar la hora local exacta.

### Privacidad

- No hay backend propio.
- En `Local`, la base local es la fuente de verdad y Health Connect no se lee ni se
  escribe automáticamente.
- En `Google Health`, Sleepy3 lee y escribe `SleepSessionRecord` en Health Connect con
  permiso explícito. La copia local se mantiene como red de seguridad.
- El historial anterior a 30 días solo se lee si el usuario concede
  `READ_HEALTH_DATA_HISTORY`; sin él, la app aplica el límite localmente y lo explica en
  Stats y en el resultado de `Import`.
- Sleepy3 no accede a la nube de Google Health ni a una API cloud; solo al proveedor de
  Health Connect del dispositivo.
- Denegar un permiso nunca bloquea el registro local.

---

## 8. Widget de pantalla de inicio (planificado)

- Implementación nativa con Jetpack Glance y `RemoteViews`; no usa el engine de Flutter.
- Dos acciones: Sleep/Wake.
- Al tocar, captura el timestamp y escribe un evento pendiente.
- El widget se actualiza cuando la app cambia el estado.
- La app aplica los eventos pendientes al arrancar o al volver al primer plano.
- Si el evento es inválido (por ejemplo, Wake sin Sleep), se descarta de forma segura.
- El diseño usa los roles del tema M3 y respeta el tema claro/oscuro.
- Test pendiente: taps con la app cerrada, evento aplicado una sola vez, estado visual.

---

## 9. Health Connect y Google Health

- API: `SleepSessionRecord` a través del paquete `health`.
- Requiere Android 9 (API 28) o superior. En Android 13 o inferior, Health Connect debe
  estar instalado.
- Fuente `Local`:
  - Drift es la fuente de verdad. Home y Stats no leen Health Connect.
  - `Sleep` y `Wake` no escriben en Health Connect.
  - Las acciones manuales `Sync`, `Add` e `Import` siguen disponibles.
- Fuente `Google Health`:
  - Home y Stats leen todas las sesiones `SLEEP_SESSION` de Health Connect, de cualquier
    app, ordenadas de más antigua a más reciente.
  - `Wake` cierra la fila local y escribe el registro en Health Connect con
    `clientRecordId = sleepy3-<startedAtMillis>` y `clientRecordVersion = 1`.
  - Si la escritura falla, la fila local queda pendiente y el reintento ocurre al abrir o
    volver a la app. El banner de Home/Stats muestra el recuento y `Retry`.
  - Una sesión pendiente no aparece en las gráficas de Google Health hasta que Health
    Connect confirma la escritura.
- Escritura idempotente: el `clientRecordId` estable evita duplicados al reintentar.
- Sesiones de duración cero: se marcan `health_sync_skipped` y no se suben.
- Acciones de copia:
  - `Sync`: sube la sesión `origin='local'` pendiente más reciente.
  - `Add`: sube todas las `origin='local'` pendientes, de la más antigua a la más reciente.
  - `Import`: lee las sesiones de Health Connect y las añade o actualiza en local.
  - La descarga deduplica por `health_record_id` y, si falta, por inicio y fin exactos.
  - Inserta las nuevas con `origin='healthConnect'` y `health_synced_at_millis`.
  - Actualiza las `origin='healthConnect'` existentes si cambiaron sus horas.
  - No sobrescribe ni borra filas `origin='local'`, y no vuelve a subir las descargadas.
  - Si ya hay una fila `origin='local'` con el mismo UUID o las mismas horas, se omite.
  - Las acciones no cambian la fuente mostrada. Si faltan permisos, se piden al pulsarlas.
- Historial:
  - `READ_HEALTH_DATA_HISTORY` se pide al elegir `All` en Stats o al iniciar `Import`.
  - Con el permiso, las lecturas empiezan en el epoch; sin él, en los últimos 30 días.
  - Stats muestra `Only the last 30 days are available` y `Allow full history` cuando el
    permiso falta; `Import` avisa en el resultado de que solo bajó 30 días.
  - El permiso se comprueba de nuevo al cargar el historial y al volver del segundo plano.
- Si el usuario deniega permisos o Health Connect no está disponible, no se bloquea el
  registro local; Settings explica el estado y ofrece `Connect` o `Install`.
- La publicación en Play Console requiere la declaración de Health Connect.
- Tests cubiertos: permiso de sueño e historial concedidos y denegados, API no disponible,
  actualización requerida, reintento idempotente, fallo parcial, deduplicación, límite de
  30 días y acciones de copia.

---

## 10. Calidad y pruebas

### Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run
dart format .
dart run build_runner build
```

### Cobertura actual

- Máquina de estados: inicio, Sleep, Wake, doble toque, clock skew.
- Persistencia: alta, cierre, restauración, sesiones abiertas duplicadas y carga de todo
  el historial cerrado.
- UI: estado inicial, cambio Sleep/Wake, restauración y layout a 360 dp.
- Cabecera, reloj en vivo y línea de sesión: formato 12/24 h, límites día/noche, timer,
  cambio de fecha y layout con texto al 200 %.
- Resumen de 3 días: agrupación por día de despertar, sesiones que cruzan medianoche,
  suma por día, media sobre días con datos, cambio de fecha, DST, estado vacío, límite
  del 100 % y semántica.
- Stats: agrupación por día, ventanas 7/30/todas, varias sesiones por día, sesiones
  abiertas y futuras excluidas, cambio de fecha, DST, `Show all`, 12/24 h, semántica,
  layout a 360 dp con texto al 200 % y `LocalDayBuilder` al pasar medianoche o volver
  del segundo plano.
- Stats en Google Health: `All` pide historial, una concesión recarga el historial
  completo, una denegación mantiene los 30 días con el banner y `Allow full history`
  vuelve a pedir el permiso.
- Settings: tema por defecto y persistido, diálogo de selección con `Cancel`/`Apply`,
  resolución `System`/`Light`/`Dark`, fuente `Local`/`Google Health`, diálogo de fuente,
  estado de conexión, `Connect`/`Install`, `Import`/`Sync`/`Add`, primer cambio con aviso
  de copia, permiso denegado, versión oculta si no está disponible, página de licencias,
  semántica, migraciones v1→v2 y v2→v3, y layout a 360 dp con texto al 200 %.
- Health Connect: disponibilidad, permisos de sueño e historial, lectura/escritura,
  cola de pendientes, reintento idempotente, banner, sesiones omitidas, acciones de copia,
  deduplicación por UUID y horas exactas, fallo parcial, protección de filas locales,
  límite de 30 días y recarga al conceder el historial.
- Tema: claro/oscuro desde la misma semilla, roles M3 y tipografía Roboto Flex.
- Build Android debug y release correctos.

### Cobertura pendiente

- Widget nativo: taps, cola de pendientes y reconciliación.
- Prueba manual del APK release en un dispositivo con Health Connect y Google Health.
- Golden tests o capturas de referencia para claro/oscuro.

### Criterio de done por módulo

1. `flutter analyze` sin issues.
2. `flutter test` en verde.
3. `flutter build apk --debug` correcto.
4. Tests nuevos para el comportamiento agregado.
5. `README.md` actualizado si el cambio es visible.
6. `SPEC.md` actualizado si cambia el comportamiento o la arquitectura.

---

## 11. Estado y roadmap

### Hecho

- Scaffold Flutter Android.
- Pantalla principal con dos botones y estado Sleep/Wake.
- Tema M3 Expressive fijo: esquemas claro/oscuro desde la misma semilla y Roboto Flex
  empaquetada.
- Persistencia Drift y restauración de sesión abierta.
- Cabecera con chip día/noche, reloj en vivo con segundos y línea de sesión.
- Resumen de los últimos 3 días con datos reales, media y barras contra una meta de 8 h.
- Pantalla `Stats` con filtros 7 días / 30 días / todo, resumen del rango y una fila por
  sesión.
- Pantalla `Settings` con tema `System`/`Light`/`Dark` persistido, fuente de datos
  `Local`/`Google Health`, estado de Google Health, acciones de copia y `About` con
  privacidad, versión y licencias.
- Health Connect: permisos de sueño e historial, lectura y escritura, cola de pendientes,
  reintento al abrir o volver a la app, banner de pendientes, acciones
  `Import`/`Sync`/`Add` y fallback de 30 días en Stats `All`.
- Builds debug (`com.sleepy3.app.debug`) y release firmada que conviven en el dispositivo.
- Releases automáticas de dos canales: pre-releases por push a `dev` y estables por push a
  `main`, con versionado, firma y notas generadas.
- Tests de estado, persistencia y UI.

### Siguiente

1. Widget de pantalla de inicio con Glance y `home_widget`.
2. Prueba manual en dispositivo del APK release y release estable (con autorización).
3. Pulido de motion y accesibilidad.

---

## 12. Decisiones abiertas

- Si se agregará un gráfico de 7 días a `Stats` en una versión posterior.
- Si el widget mostrará la duración en vivo o solo el estado.
- Si los reintentos pasarán a WorkManager en segundo plano o seguirán al abrir/volver a
  la app.
- Si `Import` recordará una denegación del permiso de historial para no volver a pedirla
  en cada intento hasta que el usuario la reactive.
- Si se agregará localización completa después de la primera release en inglés.
