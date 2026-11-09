# Sleepy3 — Especificación de producto y técnica

**Proyecto:** Sleepy3
**Plataforma:** Android
**Stack principal:** Flutter + Material 3 Expressive
**Estado:** v0.2.2, última release estable (sin widget). Home (con una sola acción
contextual), Stats (dashboard de cinco rangos con gráficos de duración, ventana y día de la
semana, insights, historial tonal con marcas de objetivo animadas, pull-to-refresh, alta
manual, edición y borrado de sesiones y detalles de solo lectura para registros de otras
apps), Settings, la persistencia local y Health Connect (Local/Google Health) funcionan. El
widget de pantalla de inicio es el siguiente bloque (0.3.0).

---

## 1. Flujo de trabajo y releases

### Ramas

- Todo el trabajo nuevo se hace en la rama **`dev`**. Los pushes a `dev` no publican
  releases: las builds de prueba se hacen en local (`flutter run` o un APK local).
- `main` permanece estable y se actualiza **solo con autorización explícita del usuario**,
  después de verificar el bloque o la funcionalidad en su máquina. El agente nunca hace
  merge ni push a `main` por iniciativa propia.
- Un push o merge a `main` **no publica nada**. La release se lanza a mano, solo cuando el
  usuario lo pide, desde `main` y eligiendo el tipo de versión.
- El trabajo no se queda solo en local: cuando el usuario dice «Haz los commits», se
  commitea **y se sube a `dev`**.
- Los tags los crea el CI; no se crean a mano.

### Forma de trabajo

- **Paso a paso:** no generar toda la app de golpe. Esperar a que el usuario pida un módulo
  o cambio concreto. Al terminar, indicar qué debe probar el usuario.
- **Aviso previo:** el agente no commitea ni hace push por iniciativa propia. Propone el
  mensaje, espera el OK y recién entonces ejecuta. «Haz los commits» autoriza commit y push
  a `dev` (sin publicar ninguna release), nunca tocar `main`.
- **Documentación como parte del cambio:** actualizar `SPEC.md` si cambia el comportamiento
  o la arquitectura, y `README.md` si el cambio es visible para el usuario.

### Idioma

- Código, comentarios, mensajes de commit y notas de release: **inglés**.
- La UI está en **inglés y español**. Todo el copy vive en `lib/l10n/app_en.arb`
  (plantilla) y `lib/l10n/app_es.arb`; los widgets no contienen strings de usuario,
  etiquetas de semántica, tooltips ni textos de diálogos.
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

#### Disparador y versiones

| Disparador | Versión | GitHub |
|---|---|---|
| `workflow_dispatch` en `main` con `bump=minor` | `v0.X.0` (sube la minor) | Latest |
| `workflow_dispatch` en `main` con `bump=patch` | `v0.X.Y` (sube el parche) | Latest |
| `workflow_dispatch` en `main` con `bump=exact` y `version=X.Y.Z` | `vX.Y.Z` (la indicada) | Latest |

- No hay releases automáticas: ni los pushes a `dev` ni los pushes a `main` publican nada.
  El workflow se lanza desde Actions → Release → Run workflow, o con
  `gh workflow run release.yml --ref main -f bump=minor` (o `-f bump=patch`, o
  `-f bump=exact -f version=0.1.6`).
- El workflow solo se ejecuta desde `main`; si se lanza desde otra rama, falla.
- Antes de lanzar, el agente confirma con el usuario el tag calculado y, cuando se apliquen
  notas curadas, el `<Tema>` del título.
- La siguiente versión sale del tag semver más alto del repositorio. `minor` incrementa la
  minor y pone el parche a cero; `patch` incrementa el parche; `exact` publica la `version`
  indicada, que debe ser mayor que el último tag.
- Ejemplos: con `v0.1.0` como último tag, `minor` publica `v0.2.0`, `patch` publica
  `v0.1.1` y `exact` con `version=0.1.6` publica `v0.1.6`. Las pre-releases antiguas de
  `dev` quedan como histórico; no se crean nuevas.
- El `versionCode` de Android es `major * 1.000.000 + minor * 1.000 + patch`
  (`v0.0.1` → 1, `v0.1.0` → 1000, `v0.2.0` → 2000). Es monótono entre versiones.
- `pubspec.yaml` no lleva la versión de la release. El workflow pasa la versión y el code
  calculados a `flutter build apk`; los builds locales siguen usando el valor del
  `pubspec`.
- Reintentar el workflow es idempotente: si ya existe un tag del mismo tipo (`minor`,
  `patch` o el `exact` indicado) apuntando al commit, se reutiliza y solo se refrescan los
  assets; no se duplican releases ni se sobrescriben títulos o notas ya curados.
- Con `exact`, un tag que ya existe en otro commit o una versión menor o igual al último
  tag hacen fallar el workflow antes de construir.

#### Notas y títulos

- Las releases se publican primero con notas generadas desde los commits convencionales
  entre el tag anterior y HEAD, agrupadas en `## ✨ Features`, `## 🐛 Fixes`,
  `## ⚡ Performance` y `## 🔧 Maintenance`. Solo se emiten las secciones con commits, más
  un enlace de changelog completo. El título inicial es el tag, sin tema.
- Después se reemplazan por las notas curadas y el título con tema.
- Formato del título curado: `vX.Y.Z - The <Tema> Update`, donde `<Tema>` resume en inglés
  lo más importante (Title Case; siempre termina en `Update`). En minors, el agente
  propone el tema y espera el OK del usuario antes de lanzar la release. En patches, si se
  aplican notas curadas, también se propone el título antes.
- Las notas curadas no viven en el repo: `release-notes/` está en `.gitignore`. La primera
  línea de `release-notes/vX.Y.Z.md` lleva el título:

```html
<!-- title: vX.Y.Z - The <Tema> Update -->
```

- Después de publicar, aplicar notas y título con:

```bash
dart run tool/apply_release_notes.dart v0.2.2
```

  El script lee el título de la primera línea y ejecuta `gh release edit`; no toca el APK.
- Estilo de las notas curadas: inglés, emojis en los títulos de sección, contexto breve, una
  sección destacada y `## ✨ What's new` con el resto. Instalación, datos, requisitos y
  actualización viven en el `README.md`, no en las notas.
- El cuerpo publicado en GitHub debe coincidir con `release-notes/vX.Y.Z.md`.

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

- Reintentar desde Actions o con `workflow_dispatch` usando el mismo `bump`. El APK también
  queda como artifact del run.
- La versión se recalcula de forma idempotente; no se publican releases duplicadas.
- Si el run falla antes de publicar, no se crea el tag ni la release: se corrige y se
  vuelve a lanzar.

---

## 2. Producto

Sleepy3 es una app Android de registro de sueño con fricción cero.

- Una acción grande: **Sleep** con un toque y un deslizamiento para confirmar que te has
  despertado. Sin formularios, sin cuentas, sin onboarding obligatorio.
- Guarda la hora exacta de inicio y fin de cada sesión.
- Los datos son locales por defecto. No hay backend ni nube propia.
- Health Connect es opcional: el usuario elige `Local` o `Google Health` como fuente de
  datos, y puede copiar sesiones entre ambos.
- `Stats` permite ajustar la hora de inicio y fin de una noche o borrarla, sin convertir
  el registro en un formulario.
- Un recordatorio diario opcional, a la hora que elija el usuario, ayuda a no olvidar
  pulsar Sleep. Es local, se puede desactivar y nunca envía datos.
- Un widget de pantalla de inicio permitirá registrar Sleep/Wake sin abrir la app.

### Objetivo de diseño

Que registrar el sueño lleve menos de dos segundos y no requiera pensar. La app debe
funcionar bien de noche, con una sola mano y con el teléfono bloqueado o desbloqueado.

### Fuera de alcance por ahora

- Cuentas, login, sincronización propia en la nube.
- UI para tablets o wearables.
- Notas, calidad de sueño y edición avanzada del historial (divisiones, etiquetas).
- Alarmas inteligentes o notificaciones basadas en los datos de sueño; el recordatorio
  diario simple sí forma parte del producto.

---

## 3. Requisitos funcionales

### 3.1 Máquina de estados Sleep/Wake

| Estado | Acción visible | Línea de sesión |
|---|---|---|
| Despierto, sin sesión previa, de día | Sleep | `No active session` |
| Despierto, sin sesión previa, de noche | Sleep | `Tap Sleep when you turn off the lights` |
| Durmiendo | Duración en vivo + Slide to wake | `Sleeping since HH:MM` |
| Despierto, con sesión previa | Sleep | `Last session: 7h 45m` |

Home muestra una sola acción, siempre habilitada: el botón **Sleep** o el deslizamiento
**Wake**. El controlador conserva sus propias guardas (`sleep()` no hace nada con una
sesión abierta y `wake()` no hace nada sin ella) para los caminos que no pasan por Home,
como el futuro widget.

Reglas:

- Un toque en **Sleep** abre una sesión con la hora actual y la persiste.
- Un deslizamiento en **Wake** que llegue al 80 % del recorrido y se suelte cierra la
  sesión abierta, calcula la duración y la persiste. El botón blanco de 104 dp viaja con
  el dedo y deja detrás un rastro `onPrimary` al 50 %. Si se suelta a partir del 80 %, el
  botón termina de viajar solo hasta el extremo derecho, donde queda a 16 dp del borde
  con la flecha visible en `primary`; la pista `primary` queda alrededor. El 80 % es una
  decisión de producto: el último 20 % es margen para el pulgar. Al soltar, **Saving
  session** permanece al menos 1,2 s mientras se escribe la copia local y, si corresponde,
  Health Connect; el texto va a la izquierda y el indicador de M3 a la derecha, con una
  figura visible de 84 dp en una caja de layout de 84 dp (su caja interna de 106 dp queda
  centrada por la proporción 38:48 y los 11 dp transparentes de cada lado no cuentan), de
  modo que el hueco texto-figura es 16 dp, igual que en Guardada. Después la pista queda
  en `primary` con el sello Amanecer (`sunny` + check) y **Session saved** durante 1,2 s,
  y vuelve el botón **Sleep**. Soltar antes del 80 % no guarda nada y devuelve el botón al
  inicio. Los diálogos de sueño corto/largo se resuelven antes de mostrar **Saving
  session**; si el usuario elige seguir durmiendo, el botón vuelve al inicio y el control
  queda accionable. La confirmación se mantiene aunque el estado ya sea «despierto». Un
  descarte muestra **Session discarded**; un fallo inesperado, **Couldn't save the
  session**.
- Mientras la sesión está abierta, el control muestra la duración compacta en la cara del
  reloj (`3 h 42 min` / `3h 42m`) y, debajo, `Desliza para despertar`. Durante el primer
  minuto muestra `Ahora` / `Just now`. La duración cambia al cambiar el minuto; no hay un
  temporizador propio, Home ya reconstruye el control con el reloj en vivo. Una luna de
  20 dp respira y la flecha se desplaza 5 dp dos veces en una entrada de 5,6 s que se
  detiene al arrastrar y se repite al volver a la app. Con movimiento reducido la entrada
  no se reproduce. La etiqueta accesible combina la duración y la acción; el cambio de
  minuto no se anuncia como región viva, pero el estado de guardado sí.
- Una sesión de menos de 10 minutos nunca se registra, en ninguna de las dos fuentes: es
  el mínimo que Health Connect acepta y los registros tan cortos son irreales. Home lo
  pregunta con un diálogo `Sleep too short` (`Keep sleeping` / `Discard session`); si el
  usuario confirma, el controlador revalida con el reloj en ese momento, de modo que una
  sesión que ya llegó a 10 minutos se cierra con normalidad. Wake alcanza a veces al
  controlador por un camino sin diálogo (por ejemplo, un toque del widget futuro): ahí el
  descarte es automático y deja constancia en el resultado de `wake()`
  (`SleepWakeOutcome.discarded`).
- Una sesión de 24 horas o más tampoco se registra (Health Connect también la rechaza).
  Home muestra `Sleep too long` con `Edit start time` y `Discard session`; descartar el
  diálogo mantiene la sesión abierta, así que no hay un tercer botón. `Edit start time`
  abre `M3EDatePicker` y `M3ETimePicker` con el inicio actual, valida el nuevo inicio con
  las mismas reglas evaluando el cierre que haría Wake ahora (rango 10 min–24 h, no
  futuro, sin solapes) y, si pasa, mueve la fila abierta y cierra la sesión en el mismo
  toque. Si no pasa, se muestra `Start time not saved` con el mensaje del error y la
  sesión sigue abierta. Sin diálogo (widget), Wake la descarta.
- Si ya hay una sesión abierta, Sleep no hace nada.
- Si no hay sesión abierta, Wake no hace nada.
- Una sesión cerrada con una hora anterior al inicio se recorta a duración cero y, por el
  mínimo de 10 minutos, se descarta en lugar de registrarse.
- Wake con una duración entre 10 minutos y 23:59:59 se registra con normalidad.
- Al arrancar la app se restaura la sesión abierta y se purgan las filas cerradas locales
  fuera del rango registrable (menos de 10 minutos o 24 horas o más) que nunca llegaron a
  Health Connect (sin `health_record_id`); sesiones ya sincronizadas y descargas de otras
  apps no se tocan.
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
- Tras Wake, el historial se relee sin vaciar la lista visible (`refreshHistory`): el
  resumen actualizado y la línea de sesión siguen en pantalla en lugar de mostrar la
  tarjeta de carga.
- La tarjeta de resumen y la tarjeta de carga comparten un alto fijo. Una copia invisible
  de la tarjeta de resumen con la duración más larga reserva el hueco, y la tarjeta visible
  lo llena. Así la columna centrada de Home no se recoloca al cargar. El estado de error
  conserva su tarjeta propia con `Retry`.

### 3.2 Navegación

- Barra de navegación flotante, content-sized y centrada (`PillNavigationBar`, 64 dp;
  crece en vertical si una etiqueta escalada necesita otra línea) con tres destinos de
  igual importancia: `Home`, `Stats` y `Settings`. El ancho se ajusta al label activo y
  se limita al ancho de la pantalla menos 32 dp (24 dp por debajo de 360 dp).
- `Home` es el destino inicial. `Stats` muestra el resumen por rango y el historial;
  `Settings` contiene apariencia, la fuente de datos, el estado de Google Health y la
  información de la app.
- El destino activo usa una píldora `secondaryContainer` de 48 dp con icono relleno y
  etiqueta; los inactivos muestran solo el icono outline en `onSurfaceVariant`, con un
  objetivo táctil de 48 dp. La etiqueta de los tres destinos sigue disponible para
  lectores de pantalla.
- El ancho de la píldora y la etiqueta se animan con los springs de M3; el icono cambia
  de outline a relleno y la etiqueta se revela al expandirse la píldora.
- El contenedor es glass: `ClipRRect` + `BackdropFilter` (blur 16), `surfaceContainer`
  al 82 % y un borde `outlineVariant` al 55 %, sin sombra.
- El `Scaffold` usa `extendBody: true`: el contenido pasa por detrás de la barra y se ve
  a través del glass. Home, Stats y Settings añaden el padding inferior de `MediaQuery`
  al final de su scroll para que el último elemento pueda subir por encima.
- M3 exige etiqueta en todos los destinos, un contenedor a todo el ancho y una superficie
  opaca. La barra content-sized, glass y con etiquetas solo en el activo es una decisión
  de diseño de Sleepy3, no una regla de M3; la etiqueta se mantiene en semántica.
- Un `IndexedStack` conserva el estado de cada pestaña al cambiar de destino, incluido
  el rango elegido en `Stats` durante la sesión de la app. `Stats` y `Settings` se
  construyen la primera vez que se seleccionan, para que el primer frame solo monte
  `Home`; después conservan su estado. El rango no se persiste entre arranques.
- Atrás desde `Stats` o `Settings` vuelve a `Home`; atrás desde `Home` sale de la app.

### 3.3 Stats e historial

- `Stats` es un dashboard de una sola columna: cabecera, cinco filtros de rango, hero,
  card de métricas, tres gráficos, card de insights y el historial. El FAB y el
  pull-to-refresh no cambian.
- Rangos: `Week` (7 días), `Month` (30), `3 months` (90), `Year` (365 rolling) y `All`
  (todo el historial cerrado). Son filter chips M3 de selección única con check leading;
  por defecto se abre en `Week`. `Year` son los últimos 365 días, no el año natural.
- La ventana incluye hoy y los días anteriores del rango; `All` empieza en la primera
  noche registrada. Las sesiones que terminan después de hoy y la sesión abierta no
  entran.
- Una noche se agrupa por el día local de despertar, igual que el historial. Varias
  sesiones el mismo día cuentan como una sola noche: la duración es la suma de las
  sesiones positivas, el bedtime es el inicio más temprano y el wake el fin más tardío.
- Hero: `Average sleep` con la media de las noches registradas, `Across {n} nights ·
  {total} total`, la comparación con el periodo anterior (`vs previous week: +18 min`)
  y la cobertura (`5 of 7 nights`; en `All`, `X nights recorded`). En `All` no hay
  comparación. En los rangos fijos se oculta si el periodo anterior no tiene datos o su
  cobertura es menor del 50 %. Sin noches muestra `—`, `No nights in this range` y
  `Show all` cuando hay historial más antiguo.
- Card de métricas 2×2 (4 columnas desde 600 dp): `Goal hit rate` (porcentaje y noches
  que cumplen), `Schedule consistency` (desviación circular del bedtime, `±32 min`),
  `Sleep balance` (`total − 8 h × noches registradas`, con `surplus` o `debt` en el
  apoyo) y `Best streak` (mejor racha del rango y racha actual). Sin datos suficientes,
  el valor es `—` y el apoyo explica por qué; nunca se inventa un 0 %.
- Gráfico `Sleep duration`: barras por bucket (día en `Week`/`Month`, semana en
  `3 months`, mes en `Year`, semanal o mensual en `All` según 180 días), línea de
  objetivo de 8 h, línea de media y huecos para noches sin datos. El tooltip da fecha,
  duración y número de sesiones; en buckets largos usa el tooltip rico con el rango y la
  media por noche.
- Gráfico `Sleep window`: una fila por bucket con una cápsula desde el bedtime hasta el
  wake, banda de mínimos/máximos y línea de media circular. El eje va de 18:00 a 12:00.
- Gráfico `By weekday`: media por día de despertar, de lunes a domingo; los días sin
  datos son huecos y el mejor día se marca con la etiqueta `Best`.
- Card `Insights`: mejor noche, noche más corta, hora media de acostarse y de
  despertarse, variación del bedtime, noches con más de una sesión y distribución
  (`<6 h`, `6–7 h`, `7–8 h`, `8–9 h`, `9 h+`). Texto factual, sin consejos ni lenguaje
  médico.
- Reglas de cálculo: media y mediana solo sobre días con datos; una noche cumple el
  objetivo si su total es ≥ 8 h (8 h exactas cuentan); la racha actual solo cuenta si la
  última noche es hoy o ayer; las horas de acostarse y levantarse usan media y
  desviación circulares en minutos desde medianoche, nunca media aritmética; los días se
  agrupan con aritmética de calendario para que el DST no desplace buckets; las
  duraciones negativas se clampan a cero y se excluyen del ritmo.
- En modo `Google Health`, elegir `3 months`, `Year` o `All` pide el permiso de historial
  de Health Connect. Si ya estaba concedido, no se vuelve a preguntar. Si se deniega, el
  rango sigue seleccionado, la lectura se limita a los últimos 30 días, un banner explica
  el límite y ofrece `Allow full history`, y los gráficos cambian su apoyo por
  `Last 30 days available` en lugar de afirmar que cubren el rango completo. `Week` y
  `Month` no piden nada. Al volver del segundo plano se relee el permiso por si el
  usuario lo cambió en Health Connect.
- Debajo, una tarjeta tonal por sesión cerrada, de la más reciente a la más antigua,
  también dentro de un mismo día. En `Week` cada tarjeta tiene tres líneas: el día de
  despertar en una píldora (`Today`, `Yesterday`, `Tue, Oct 20` o con año si no es el año
  actual), la duración como headline y `inicio – fin` como supporting text. En `Month`,
  `3 months`, `Year` y `All` la tarjeta es compacta de dos líneas: la píldora del día y,
  si la sesión viene de otra app, su cápsula de origen arriba, y duración y rango en la
  segunda línea.
- Las tarjetas parten de la pareja de filled card `surfaceContainerHighest` / `onSurface`.
  La sesión más reciente del día más reciente usa el acento `primaryContainer` /
  `onPrimaryContainer`; las dos siguientes mezclan ese acento con la base al 2/3 y 1/3, y
  desde la cuarta todas usan la base. Solo la destacada usa el `onPrimaryContainer`; las
  mezcladas mantienen `onSurface`. El degradado empieza en la sesión destacada, que es
  siempre la primera de la lista. Es una decisión de diseño: M3 no tiene un rol de
  degradado por recencia; los extremos son roles estándar. La píldora del día usa el
  `on*` de la tarjeta al 10 % y el texto `on*`
  (decisión de diseño: M3 no tiene un rol de container “on-color al 10 %”). La marca
  inicial compara la duración con el objetivo de 8 h de Home: por debajo es un anillo de
  progreso con un icono `bedtime`; al llegar o superarlo se sustituye por un
  `clover8Leaf` de la librería de formas M3, relleno `primary` y con el icono en
  `onPrimary`. Mide 44 dp en `Week` y 36 dp en los demás rangos. La forma es un refuerzo
  decorativo: la etiqueta hablada añade `goal met` cuando se cumple. En la lista la marca
  es estática; el movimiento vive solo en los detalles de la sesión.
- Las sesiones escritas por otra app muestran una cápsula junto a la píldora del día,
  con `open_in_new_outlined` y el label Android de la app que las creó (`Samsung
  Health`); si Android no resuelve el paquete, dice `Another app`. Las sesiones propias
  no llevan distintivo, aunque estén subidas a Google Health. En `Local` solo se marcan
  las copias descargadas de otra app; una copia descargada de Sleepy3 sigue siendo
  propia. En `Google Health` se marcan todos los registros que no escribió Sleepy3. La
  flecha indica que la sesión viene de otra app; el estado de solo lectura queda en la
  etiqueta hablada (`Read-only, from {app}`) y en la card `Read-only session` de los
  detalles. La cápsula usa el mismo stadium y el mismo tinte del 10 % que la píldora del
  día (decisión de diseño: M3 no tiene una etiqueta de estado no interactiva).
- Las sesiones no se agrupan en una tarjeta por día: si hubo varias el mismo día, cada
  una conserva su propia tarjeta. La media y el total sí agrupan por día de despertar,
  con la misma regla que Home (3.1.2).
- Las sesiones abiertas no entran en la media, el total ni la lista. Si hay una abierta,
  la cabecera lo explica con `Sleeping since {time} · it will appear when you wake.`
- Sin ninguna sesión cerrada se muestra un empty state. El texto cambia si hay una sesión
  abierta para explicar que la primera noche aparecerá al despertar.
- `Stats` se recarga con un pull-to-refresh, también desde el empty state. La pantalla no
  se mueve: un indicador M3 Expressive contenido de 48 dp (forma activa de 38 dp, el
  default de M3) baja desde el borde superior siguiendo el gesto. Mientras se arrastra
  la forma rota con el dedo; al soltar, el loader se queda en la posición alcanzada,
  limitada a 56–140 dp desde el borde, empieza a mutar y a girar, y al terminar sube y se
  desvanece. El umbral de recarga es 80 unidades de pull y el dedo se aplica a 0,6×. Es
  una variante de diseño: M3 mantiene el indicador anclado arriba.
- La recarga no vacía la lista: las filas siguen visibles mientras se lee la fuente. Si la
  lectura falla, se conservan y aparece `Couldn't refresh your sleep history. Try again.`.
  En `Google Health` primero se reintentan las subidas pendientes y después se relee el
  permiso de historial y las sesiones; en `Local` solo se reintentan actualizaciones de
  sesiones que ya tienen registro en Health Connect y nunca se sube una sesión nueva.
- La fecha y la ventana se recalculan a medianoche local y al volver del segundo plano
  con `LocalDayBuilder`, no con un reloj que reconstruye cada segundo. Los días se
  calculan con aritmética de calendario para no desplazar los grupos con DST.
- Todas las filas abren la sesión con un toque en toda la fila; no hay icono de edición.
  El lector de pantalla anuncia la fila como botón con la pista `Opens the session`.
- En `Local` se pueden editar y borrar las sesiones cuya fila Drift pertenece a Sleepy3.
  Las filas descargadas de Health Connect (`origin='healthConnect'`) abren una vista de
  solo lectura: una importación posterior podría reemplazarlas.
- En `Google Health` se pueden editar y borrar todos los registros escritos por Sleepy3
  (paquete release `com.sleepy3.app` o debug `com.sleepy3.app.debug`), tengan o no copia
  local. Si existe una copia local con `healthClientRecordId`, se reutiliza su id y
  versión; si no, la app lee `clientRecordId` y `clientRecordVersion` de Health Connect y
  escribe la versión siguiente, actualizando el mismo registro. Los registros de otras
  apps abren la vista de solo lectura.
- La vista de solo lectura usa el mismo hero y el título `Session`. Los campos son
  filas estáticas: no abren pickers, no llevan los iconos de calendario o reloj y no hay
  `Save` ni `Delete`. Entre el hero y `Fell asleep` muestra una card `Read-only session`
  que explica que la sesión se creó en otra app y no se puede editar desde Sleepy3. La
  card usa el label Android del paquete de origen (`Google Health`, `Samsung Health`,
  etc.) y cae a `another app` cuando el paquete no está instalado o no se puede resolver.
  En `Local`, una copia descargada de Sleepy3 invita a cambiarse a `Google Health` para
  editarla.
- El panel de sesión es un diálogo adaptativo M3: pantalla completa en ventanas
  compactas y diálogo básico en medianas y grandes. Título `Session`, acción
  `Save` y cierre con `Cancel` o la X. Arriba, una card `primaryContainer` con la
  duración en vivo en `headlineMedium`, el día de despertar y el objetivo de 8 h: una
  marca de 56 dp (el `clover8Leaf` si se cumple, el anillo si no) y una línea
  `Goal met · 13m over the 8h goal`, `Goal met` o `58m short of the 8h goal`; con un
  borrador sin duración dice `Your 8h goal`. La marca cobra vida solo aquí: si el objetivo
  se cumple, el `clover8Leaf` gira continuamente en sentido horario, una vuelta cada 8 s,
  y la luna queda erguida; si no, el anillo espera 400 ms y se dibuja de 0 al porcentaje
  real en 600 ms (`long4` + `emphasizedDecelerate`, sin rebote) y después se queda quieto.
  Al cruzar el objetivo con el borrador, el clover toma el relevo y, al volver atrás, el
  giro se detiene. Con «Quitar animaciones» de Android ambas marcas quedan fijas. El giro
  continuo de 8 s, rotar solo el clover y limitar el movimiento a los detalles son
  decisiones de diseño; M3 sí documenta que las formas pueden comunicar progreso girando.
  Debajo, las secciones `Fell asleep` y
  `Woke up` tienen filas de fecha y hora cuyo headline es el valor y cuyo icono final
  abre `M3EDatePicker` o `M3ETimePicker`. La fecha omite el año cuando es el actual.
  Duración y objetivo se recalculan con el borrador; un aviso explica cuando la sesión
  también está en Google Health.
- Bajo `Woke up`, la card `Night context` compara la sesión con la media de las últimas
  7 noches registradas hasta su día de despertar (`+12 min vs your 7-night average`,
  `Bedtime 22 min later`, `Wake 5 min earlier`) y, dentro del rango seleccionado en Stats,
  la sitúa como `Longest session in this range` o `2nd longest session in this range`. Con
  menos de 2 noches oculta la comparación y muestra `Not enough nights yet.`; si la noche
  tiene varias sesiones, el apoyo lo dice y las comparaciones siguen siendo de la sesión,
  no del total del día. La card aparece también en solo lectura y no cambia el candado
  ni el texto de la card `Read-only session`.
- La vista de solo lectura reutiliza el contenido del editor: pantalla completa en
  compacto con solo la X de cierre y diálogo básico en mediano y expandido con una única
  acción `Close`. No muestra `Save` ni `Delete`.
- Validación del borrador: el fin debe ser posterior al inicio, la sesión debe durar al
  menos 10 minutos (`SessionEditError.tooShort`) y menos de 24 horas
  (`SessionEditError.tooLong`), idéntica regla en las dos fuentes; unas horas no pueden
  estar en el futuro y la sesión no puede solaparse con otra cerrada ni con la sesión
  abierta. Los errores se muestran inline y el editor no se cierra. Un fallo de guardado o
  borrado abre un diálogo básico encima del editor.
- Guardar y borrar dependen de la fuente:
  - `Local`: una sesión sin registro en Health Connect solo cambia en Drift. Si ya está
    en Health Connect, primero se guarda la copia local y se marca pendiente, y después
    se actualiza el mismo registro; si falla o falta permiso, la fila queda pendiente y
    el editor se cierra con un aviso. Al borrar, Health Connect se borra primero; si
    falla, la copia local se conserva.
  - `Google Health`: Health Connect se escribe o borra primero. Solo si la plataforma
    confirma se actualiza o elimina la copia local y la lista visible. Si falla, el
    editor sigue abierto y no cambia nada.
- `Save` sin cambios cierra sin escribir. Cerrar con cambios sin guardar pide
  confirmación (`Discard unsaved changes?`). El borrado pide confirmación aparte.
- Al guardar o borrar, la lista y el resumen se actualizan desde el estado en memoria, sin
  recargar el historial ni mostrar el spinner. Solo se muestra un snackbar cuando hay algo
  que contar: guardado con sincronización pendiente, permiso necesario o sesión borrada.
#### 3.3.1 Alta manual de sesiones

- `Stats` muestra un FAB de 56 dp (tamaño regular de M3, el de la referencia) como
  acción final del grupo de navegación inferior: la píldora de cristal y el FAB se
  centran juntos, con 12 dp entre ambos y el FAB a la misma altura que la píldora.
  Queda a la derecha del dock, lejos del borde de la pantalla. Al entrar en `Stats` la
  píldora se desplaza unos 34 dp a la izquierda para dejar sitio al FAB; en Home y
  Settings vuelve al centro. Es una decisión de diseño usar el regular en lugar del
  mediano que M3 recomienda por defecto, colocar el grupo junto al dock en lugar de un
  FAB suelto en la esquina, y usar el estilo relleno `primary` en lugar del
  `primaryContainer` tonal.
- El FAB usa `primary` / `onPrimary`, icono relleno de suma (`add_rounded`) de 24 dp,
  radio de 28 dp (círculo, la mitad de los 56) y tooltip/etiqueta accesible
  `Add a sleep session`. El círculo acompaña la forma stadium del dock; el relleno
  primario lo convierte en la acción principal. Solo aparece en `Stats` y solo cuando
  el historial está listo: durante la carga o tras un error no se muestra (M3 pide
  retirar un FAB no disponible, no deshabilitarlo). El grupo reserva su hueco mientras
  está en Stats, así que la píldora no se mueve cuando el FAB aparece. Permanece fijo
  al hacer scroll.
- Al entrar en `Stats` con el historial listo, el FAB entra desde el borde derecho del
  dock: 42 dp desde la izquierda, escala 0.86→1 y opacidad 0→1. Posición y escala usan
  el spring `expressiveSpatialFast`; la opacidad usa `effectsFast`, sin rebote. El plus
  entra 60 ms después con el mismo par de springs. El retardo es una decisión de
  diseño: M3 no publica valores de stagger. La entrada deslizante también es una
  decisión de diseño; la aparición canónica de M3 expande desde el centro o el borde
  inferior. Con `disableAnimations` el FAB aparece directamente en su sitio.
- Al pulsarlo se abre `M3EDialog.showAdaptive` con título `New session` y acción `Add`.
  El contenido reutiliza el hero y las secciones `Fell asleep` / `Woke up` del editor:
  la duración y el objetivo se recalculan con el borrador. Cerrar con cambios pide
  `Discard unsaved changes?`; sin cambios no pregunta.
- El borrador inicial es la última noche: ayer a las 23:00 → hoy a las 07:00. Si ahora
  es antes de las 07:00, termina en `now` con precisión de minuto. Es una decisión de
  diseño; el usuario puede ajustar fecha y hora.
- Los dos date pickers limitan la fecha a hoy; una hora futura de hoy se rechaza al
  validar. Se reutiliza `validateSessionEdit`: fin posterior al inicio, duración entre
  10 minutos y menos de 24 horas, sin inicio ni fin en el futuro y sin solape con una
  sesión cerrada ni con la abierta. Los errores se muestran inline, también en vivo
  tras el primer cambio, y el diálogo no se cierra.
- En `Local` la fila se inserta en Drift y se añade al estado en memoria: el historial
  y el resumen se actualizan al instante, sin recargar. En `Google Health` se escribe
  primero la copia local de seguridad con el `clientRecordId` estable
  (`sleepy3-<inicio>`), después se sube a Health Connect y solo si la plataforma
  confirma se relee el historial. Si la subida falla, la fila queda pendiente, la lista
  visible sigue mostrando solo Health Connect y el snackbar y el banner de pendientes
  lo explican. La sesión creada es editable y borrable como cualquier sesión propia.
- El FAB vive dentro del alto del dock, así que la lista y el empty state no reservan
  espacio extra al final y la última tarjeta no queda debajo del botón.
- Límites: no se añaden notas ni calidad de sueño; solo inicio, fin y borrado. La sesión
  abierta no aparece en Stats y no se edita desde esta pantalla.
- Si una actualización de Health Connect falla desde `Local`, las dos copias pueden estar
  distintas hasta que funcione el reintento; la fila queda pendiente y Settings muestra el
  contador.

### 3.4 Settings

- La pantalla tiene cabecera `Settings` y línea de apoyo
  `Theme, reminders, sleep data and app info.`, seguida de cinco secciones:
  `Appearance`, `Reminders`, `Sleep data`, `Google Health` y `About`.
- Cada sección usa un encabezado `titleMedium` emphasized y una lista agrupada
  `M3EList`/`M3EListItem` con radio exterior 16 dp, interior 4 dp y gap 2 dp.
- `Appearance` contiene:
  - `Theme`, cuyo supporting text muestra el modo actual: `System`, `Light` o `Dark`.
    Al tocarla se abre un diálogo M3 de selección con opciones de radio y acciones
    `Cancel` / `Apply`. `Apply` aplica y persiste el modo; `Cancel` no cambia nada. El
    valor por defecto es `System`.
  - `Time format`, cuyo supporting text muestra `12-hour` o `24-hour`. Al tocarla se abre
    el mismo diálogo de selección con `Cancel` / `Apply`. El formato se aplica al reloj, a
    las horas de sesión, al historial y a los selectores de hora. Si no hay preferencia
    guardada, el primer arranque toma el formato del teléfono y lo persiste.
  - `Language`, cuyo supporting text muestra `English` o `Español`. El diálogo solo
    ofrece esos dos idiomas, sin `System`. Si no hay preferencia guardada, el primer
    arranque resuelve el idioma del teléfono (`es` → Español; cualquier otro → English),
    lo persiste en `preferences` (`language`) y lo aplica a toda la app.
- `Reminders` contiene:
  - `Sleep reminder`, un interruptor con apoyo `Off` o `Every day at {time}`. Al
    activarlo se pide permiso de notificaciones si hace falta y se programa el aviso
    diario; si se deniega, el interruptor sigue apagado y un snackbar ofrece
    `Open settings`. El valor por defecto es desactivado a las 22:00.
  - `Reminder time`, visible solo con el recordatorio activo, muestra la hora actual y
    abre `M3ETimePicker`. Cambiar la hora cancela la programación anterior y guarda la
    nueva.
  - `Sleep in progress`, un interruptor con apoyo `Shows a live timer while you sleep.` o
    `Off`. Está activado por defecto. Al activarlo se pide permiso de notificaciones si
    hace falta; si se deniega, sigue apagado y un snackbar ofrece `Open settings`. Al
    desactivarlo se cancela la tarjeta al momento y no se publica en el siguiente Sleep.
    Es independiente de `Sleep reminder`.
  - Si Android bloquea las notificaciones de la app, aparece una fila
    `Notifications are off` con `Allow Sleepy3 to send the notification.` que abre los
    ajustes de notificaciones del sistema. La fila se muestra cuando el recordatorio
    está activo; la tarjeta de sueño usa el aviso de permiso al intentar activarse.
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
  Cuando la copia cambia algo, el historial visible se recarga para que la lista y la
  cápsula de origen reflejen las filas añadidas o actualizadas.
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

#### 3.4.1 Recordatorios de sueño

- Es un recordatorio local diario, no una notificación push. No hay servidor ni se envía
  ningún dato de sueño; el texto solo invita a abrir Sleepy3.
- Se guarda en `preferences` con `sleep_reminder_enabled` y `sleep_reminder_time`
  (`HH:mm`). Sin preferencia, el valor por defecto es desactivado a las 22:00.
- El permiso `POST_NOTIFICATIONS` se pide solo al activar el interruptor (Android 13+),
  nunca al arrancar. Una denegación deja el recordatorio apagado y ofrece abrir los
  ajustes de notificaciones.
- Se programa con una alarma diaria del sistema a la hora local elegida. En esta versión
  la alarma es **inexacta**: no se pide `SCHEDULE_EXACT_ALARM` y Android puede retrasarla
  unos minutos, sobre todo con ahorro de batería. Los reinicios y las actualizaciones de
  la app se cubren con `RECEIVE_BOOT_COMPLETED` y el `ScheduledNotificationBootReceiver`.
- Si ya hay una sesión abierta (el usuario ya pulsó Sleep), el aviso no se envía y la
  programación se cancela; al despertar se vuelve a programar. La app sincroniza el
  recordatorio al arrancar, al volver al primer plano, al cambiar Sleep/Wake y al cambiar
  el idioma, de modo que el texto de la notificación queda en el idioma actual.
- Tocar la notificación abre Sleepy3 en `Home`, incluso si la app estaba en `Stats` o
  `Settings`. No inicia ni cierra una sesión por sí sola.
- Si el usuario revoca las notificaciones después de activarlo, la preferencia sigue
  activa pero Settings muestra la fila de aviso.
- El canal de Android se llama `Sleep reminder` y usa importancia alta para que el aviso
  se vea; el usuario puede ajustarlo en los ajustes del sistema. Es una decisión de
  producto, no un token M3.
- La notificación usa un icono monocromo generado desde la marca
  (`android/app/src/main/res/drawable-*/ic_notification.png`) y la programación usa un id
  fijo, así que cambiar la hora reemplaza la anterior.

#### 3.4.2 Notificación de sueño en curso

- No es un recordatorio: es una notificación de estado que solo existe mientras hay una
  sesión abierta. La pinta un puente Android (`SleepingNotificationBridge`) con un
  `RemoteViews` propio; el plugin local sigue gestionando el permiso y el recordatorio. Usa
  id fijo `1002` y canal propio `sleep_status`; no hay servidor ni se envía ningún dato.
- La tarjeta usa `Notification.DecoratedCustomViewStyle` con una vista colapsada de 64 dp y
  una expandida: marca de Sleepy3 en un círculo claro, `Durmiendo`, un `Chronometer` grande
  y el objetivo. La cabecera del sistema muestra `En curso` y oculta el timestamp duplicado.
- El cronómetro es un `Chronometer` de `RemoteViews` con base convertida desde `startedAt`
  a `SystemClock.elapsedRealtime()`; no hay un `Timer` de Dart ni un foreground service.
  Por eso sigue contando aunque el proceso de la app muera y no consume batería.
- El título es `Sleeping`/`Durmiendo` y el cuerpo combina `dailySleepGoal` con la hora a la
  que se cumple: `Goal 8h · until 7:30 AM` / `Objetivo 8 h · hasta las 7:30`. La hora
  respeta el formato 12/24 y el idioma actuales.
- Si el `fontScale` del sistema supera 1.2 o el layout personalizado no se puede inflar, el
  puente publica la notificación estándar con título y cuerpo; el estado nunca se pierde y
  el texto sigue siendo legible.
- Se muestra al pulsar Sleep, se restaura al arrancar o volver al primer plano si hay una
  sesión abierta (por ejemplo, tras un crash) y se cancela al despertar o al descartar la
  sesión. También se vuelve a publicar si cambia la hora de inicio de la sesión abierta, el
  idioma o el formato horario.
- El interruptor `Sleep in progress` de Ajustes se guarda en `preferences` como
  `sleep_status_notification_enabled` (ausente = activado). Desactivarlo cancela la
  tarjeta al momento y evita publicarla; activarlo la muestra si hay una sesión abierta.
  Al activarlo se pide permiso si falta; una denegación deja el interruptor apagado y
  ofrece abrir los ajustes de Android. Es independiente del recordatorio nocturno.
- En Android 13+ el permiso se pide al activar el interruptor o en el primer Sleep con la
  notificación activada, y como máximo una vez. La marca
  `sleep_notification_permission_asked` en `preferences` evita repetir el diálogo; una
  denegación deja la notificación oculta y no rompe el seguimiento. El usuario puede
  habilitar después las notificaciones o el canal en Android y la notificación vuelve en
  la siguiente sincronización.
- Tocar la notificación abre `Home` mediante un `PendingIntent` a `MainActivity`; si la app
  ya estaba abierta en otra pestaña, `onNewIntent` avisa a Dart y `Sleepy3Shell` selecciona
  `Home`. El canal es independiente del recordatorio, así que se puede desactivar solo este
  aviso sin perder el recordatorio nocturno.
- Tras reiniciar el teléfono la notificación no se restaura por sí sola: vuelve a aparecer
  al abrir Sleepy3 si la sesión sigue abierta. No se añade un receiver nativo ni un
  foreground service en esta iteración.

### 3.5 Widget de pantalla de inicio (0.3.0)

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
  con `origin='healthConnect'`, guarda el paquete de origen en `source_id`, actualiza las
  descargadas que cambiaron y nunca sobrescribe ni borra filas `origin='local'`. Las
  descargadas no se vuelven a subir. Una importación posterior rellena `source_id` en las
  filas descargadas antiguas que todavía no lo tengan.
- Editar y borrar desde Stats respeta la fuente:
  - En `Local`, editar una sesión ya sincronizada actualiza el mismo registro de Health
    Connect usando el `clientRecordId` guardado y una versión mayor. Borrar una sesión con
    registro borra primero en Health Connect y después la fila local.
  - En `Google Health`, la escritura o el borrado van primero a Health Connect; la copia
    local y la lista visible solo cambian cuando la plataforma confirma.
  - Los registros de otras apps y las copias descargadas en `Local` abren una vista de
    solo lectura; no se escriben ni se borran desde Sleepy3. Un registro propio de Health
    Connect sin copia local se actualiza en su sitio con los metadatos de Health Connect,
    sin duplicarlo.
- Los reintentos de `Sleepy3App` dependen de la fuente. En `Local` solo reintenta
  actualizaciones de sesiones que ya tienen registro en Health Connect; nunca sube
  sesiones nuevas automáticamente. En `Google Health` reintenta todas las pendientes,
  incluidas las altas.
- El pull-to-refresh de Stats comparte esa regla antes de releer: `retryPending` sube todas
  las pendientes en `Google Health` y solo actualiza las ya sincronizadas en `Local`.
  Después relee la fuente elegida sin vaciar la lista visible.
- Los permisos se piden al usar la función, no en el primer arranque. Si Health Connect no
  está disponible o el permiso se deniega, la app sigue funcionando localmente.
- Sleepy3 lee y escribe en Health Connect, no en la nube de Google Health. Un registro que
  solo esté en la nube aparece cuando Google Health lo sincroniza con Health Connect.
- El historial completo (más de 30 días) requiere `READ_HEALTH_DATA_HISTORY`. Sleepy3 lo
  pide al elegir `3 months`, `Year` o `All` en Stats o al usar `Import`; si se deniega,
  aplica un límite de 30 días por su cuenta. Stats muestra el banner
  `Only the last 30 days are available` con `Allow full history`, los gráficos cambian su
  apoyo por `Last 30 days available`, e `Import` añade al resultado
  `Only the last 30 days were downloaded.`. El permiso se relee al cargar el historial y
  al volver del segundo plano, así que una concesión hecha en Health Connect se aplica sin
  reiniciar la app.

### 3.7 Accesibilidad

- Objetivo táctil mínimo de 48 × 48 dp.
- Etiquetas visibles y descripciones accesibles.
- Foco visible en botones. El anillo del deslizamiento Wake es solo para teclado
  (`FocusHighlightMode.traditional`): arrastrar con el dedo no enfoca el control ni deja
  el borde puesto.
- Respetar el tamaño de texto del sistema; la etiqueta del botón Sleep y las del
  deslizamiento se ajustan sin truncarse, incluso con el 200 % de texto.
- El control dormido mantiene visibles la duración y `Desliza para despertar` sin
  truncarse al 200 %. La entrada de la luna y la flecha es de una sola pasada y respeta
  el movimiento reducido; el cambio de minuto no se anuncia como región viva, pero el
  estado de guardado sí.
- Home solo muestra la acción que corresponde al estado y siempre está habilitada.
- El deslizamiento Wake expone una acción de botón para lectores de pantalla: doble
  toque completa el gesto sin arrastrar. También responde a Enter/Espacio y a las
  flechas. El control mantiene el objetivo táctil de 104 dp y el estado *dragged* del
  16 %. El botón blanco viaja hasta el extremo derecho y deja un rastro `onPrimary` al
  50 %; la flecha permanece en `primary` al 100 %.
- El cambio entre Sleep y Wake hace un morph de forma de 350 ms entre el cuadrado de
  28 dp y la píldora de 68 dp. Con movimiento reducido el cambio es inmediato.
- El cierre usa el sello `sunny` de M3 (Amanecer), que entra girando 360° hacia la
  derecha mientras sube el fade y se detiene; el check entra después, cuando el sol ya
  está quieto, y el texto desde la izquierda. Con movimiento reducido aparece
  directamente.
- Tras cambiar de acción, una guarda de 400 ms ignora arrastres y toques (decisión de
  producto) para que un segundo gesto no cierre la sesión que se acaba de abrir.
- La recarga de Stats es solo por gesto (decisión de producto). Para lectores de pantalla
  hay una acción `Refresh sleep history`; M3 pide además una acción visible sin gesto (por
  ejemplo, un icono `Refresh` en la cabecera), pendiente. El indicador expone
  `Refreshing sleep history` como etiqueta de progreso.

---

## 4. UX y diseño visual

- Este apartado se apoya en la skill `.agent-skills/m3-expressive/`: se lee
  `SKILL.md` antes de proponer o tocar UI y se consultan las referencias visuales
  (`visuals/INDEX.tsv` por caption más las imágenes de anatomía, medidas, estados,
  placement y do/don't). Cada decisión visual cita el archivo de referencia y las
  imágenes usadas. Las imágenes son apoyo de composición: las medidas autoritativas
  son `references/tokens.md` y `references/component-tokens.md`.
- Material Design 3 Expressive con **tema fijo de marca**. Sin color dinámico
  (Material You).
- Paleta exacta:
  - claro: `surface #EFF4F9`, `primary #252B81`, `onPrimary #FFFFFF`;
  - oscuro: `surface #121318`, `primary #C6CCF7`, `onPrimary #272B60`.
  Los roles `surfaceContainer*`, `surfaceDim/Bright`, `onSurface*`, `outline*` e
  `inverseSurface*` siguen los pasos tonales de superficie de M3, desplazados para que
  `surface` sea exactamente el fondo de marca. `primaryContainer`, `secondary`,
  `tertiary` y `error` se generan desde el indigo del logo (`#252B81`). Los pares de
  texto mantienen al menos 4.5:1 y `outline` al menos 3:1.
- El modo sigue al sistema por defecto. Desde `Settings` se puede fijar `System`,
  `Light` o `Dark`; la elección se aplica al instante y se conserva entre arranques.
- El formato de hora es `12-hour` o `24-hour`; se elige en `Settings` y se guarda en
  `preferences` (`time_format`). Sin preferencia, el primer arranque fija el formato del
  teléfono. `Sleepy3App` inyecta el valor en `MediaQuery.alwaysUse24HourFormat`, así que
  reloj, historial, editores y `M3ETimePicker` comparten la misma elección.
- El idioma es `English` o `Español`; se elige en `Settings` y se guarda en
  `preferences` (`language`). Sin preferencia, el primer arranque resuelve el idioma del
  teléfono y lo persiste. No hay opción `System`. `Sleepy3App` pasa el `Locale` y los
  delegates de `AppLocalizations`; fechas y horas usan el `localeName` resuelto.
- Tipografía **Space Grotesk variable** empaquetada como asset (`assets/fonts/`, OFL) para
  toda la escala. Se usan los tamaños, pesos y tracking de la escala M3; no se usan
  pesos 850/950 en los tokens. La fuente solo tiene el eje `wght` (300–700).
- Los títulos de Home, Stats y Settings usan **Google Sans Flex instanciada**
  (`assets/fonts/GoogleSansFlex-Titles.ttf`, también OFL) con `wght` 900, `wdth` 112,5 y
  `ROND` 35 fijados en el asset y solo `opsz` vivo (28–32). Es una decisión de diseño
  fuera de M3 (la escala emphasized llega a Bold 700) y no altera los tokens de peso.
- Mapeo tipográfico:
  - reloj: `displayLarge` emphasized en Space Grotesk **700** con cifras tabulares
    (`Sleepy3Theme.clock`). El token emphasized es 500; el 700 es una decisión de diseño
    dentro del máximo de la escala;
  - AM/PM: `titleMedium`;
  - marca: `headlineLarge` emphasized en Google Sans Flex instanciada;
  - títulos de Stats y Settings: `headlineMedium` emphasized en Google Sans Flex
    instanciada;
  - fecha y copy de apoyo: `bodyMedium` (la línea de sesión, emphasized);
  - chip día/noche: `labelMedium`;
  - cabecera y tarjeta de resumen de Home: `titleMedium` y `labelMedium` (la tarjeta no
    necesita `bodyMedium`).
- La ilustración de luna/sol del prototipo no forma parte de la UI.
- Navegación:
  - Barra flotante, content-sized y centrada (`PillNavigationBar`), 64 dp, con margen
    mínimo de 16 dp (12 dp por debajo de 360 dp) y 12 dp sobre el inset inferior del
    sistema. El ancho máximo de la píldora es la pantalla menos 32 dp (24 dp por debajo
    de 360 dp), menos el FAB y su hueco cuando el grupo los incluye.
  - Contenedor glass: `ClipRRect` + `BackdropFilter` (blur 16), `surfaceContainer` al
    82 % y borde `outlineVariant` al 55 %, sin sombra. La píldora activa es opaca.
  - Tres destinos: `Home`, `Stats` y `Settings`. El activo usa una píldora
    `secondaryContainer` de 48 dp con icono relleno y etiqueta; los inactivos, solo
    icono outline en `onSurfaceVariant`.
  - En `Stats`, el FAB de alta manual es el `trailing` de la barra: la píldora y el FAB
    se centran como grupo con 12 dp entre ambos; el ancho máximo de la píldora descuenta
    el FAB y el hueco. El FAB mide 56 dp, usa `primary` / `onPrimary`, el icono de suma
    de 24 dp y un radio de 28 dp. No añade altura al dock porque mide menos que los
    64 dp de la píldora.
  - `Stats` usa `analytics_outlined` / `analytics`; el estado vacío de Stats usa
    `analytics_rounded`.
  - La etiqueta inactiva se oculta visualmente pero se conserva en semántica.
  - `Scaffold.extendBody` deja el contenido detrás de la barra. Home, Stats (incluidos
    vacío, carga y error) y Settings suman el padding inferior de `MediaQuery` a su
    scroll para que el último elemento pueda subir por encima.
  - `Stats` y `Settings` tienen contenido (ver abajo).
- Pantalla principal:
  - Cabecera centrada: `Sleepy3` en `headlineLarge` emphasized y un chip de estado
    (`Day · ready to wake` / `Night · time to rest`) en `labelMedium`. El chip no es un
    componente M3: es una etiqueta de estado construida con los roles y la forma full
    de M3.
  - Reloj en vivo en `displayLarge` emphasized, con segundos, cifras tabulares y
    `AM`/`PM` en `titleMedium` cuando el sistema usa 12 h.
  - Fecha en `bodyMedium` y línea de sesión en `bodyMedium` emphasized. La línea de
    sesión hace crossfade (220 ms) cuando cambia, para que el paso a «durmiendo» no
    sea un salto de texto.
  - El reloj es una línea única. Si el tamaño de texto del sistema no cabe en el ancho,
    solo el reloj se reduce; el resto del texto respeta la escala del sistema.
  - La pantalla solo hace scroll cuando el contenido no cabe por encima de la barra
    flotante. El padding inferior de `MediaQuery` (alto de la barra más inset del sistema)
    no añade recorrido por sí mismo.
  - El estado despierto usa un `M3EButton.icon` XL de 136 dp de alto, forma square
    (radio 28 dp), estilo `filled`, icono leading de 40 dp (luna) y etiqueta
    `titleLarge` emphasized (22/28/0) con `Sleepy3Theme.brandTitle` (Google Sans Flex
    900, `opsz` 28) dentro de un `FittedBox`. Usa `primary`/`onPrimary`; el padding
    horizontal de 64 dp es el token XL. M3 documenta `labelLarge` para botones y el
    componente XL de M3E usa `titleLarge`; la fuente de marca a 22 dp es una decisión
    de diseño.
  - La pulsación del botón Sleep usa el radio pressed de M3: 28 → 16 dp en 200 ms y una
    escala de 0.98, con state layer del 10 % y un háptico ligero al apoyar el dedo. Al
    soltar, la superficie continúa desde 16 dp hasta el radio 68 dp de la píldora; la
    sesión se crea en el instante del toque, no al terminar la animación. En la
    transición despierto → durmiendo, un velo `onPrimary` al 14 % cruza la superficie
    una vez (520 ms, curva effects) y la luna de la fila aterriza con medio giro
    (420 ms, spatial fast). La escala y el velo son decisiones de producto; los radios,
    el state layer y las curvas son M3. Con movimiento reducido no se reproduce el velo
    ni el aterrizaje y el cambio es inmediato. El aterrizaje no se repite al restaurar
    una sesión abierta.
  - El estado durmiendo usa un control propio de 136 dp: una pista `primary` de 68 dp de
    radio con un botón `onPrimary` de 104 dp y radio 52, y una flecha en `primary`. El
    botón viaja de `left: 16` a `left: 208` (16 dp de inset + 192 de recorrido) y deja
    detrás un rastro `onPrimary` al 50 % de 104 dp de alto y ancho `104 + offset`; en
    reposo el rastro queda oculto bajo el botón.
    La línea principal es la duración compacta de la sesión (`3 h 42 min` / `3h 42m`,
    `Ahora` / `Just now` durante el primer minuto), precedida por una luna de 20 dp; debajo
    va `Slide to wake` a 14 dp. La duración usa `Sleepy3Theme.clock` sobre
    `headlineSmall` emphasized (24/32, Space Grotesk 700 con cifras tabulares) y la pista
    usa `Sleepy3Theme.brandTitle` sobre `labelLarge` (14/20, Google Sans Flex 900). El
    bloque de texto empieza 24 dp después del borde del botón en reposo (`space300` de la
    escala de 8 dp); el ancho restante se ajusta con `FittedBox`. La luna respira y la
    flecha se desplaza dos veces en una entrada de 5,6 s que no se repite en bucle y se
    detiene al arrastrar; al volver a la app se reproduce una vez. Con movimiento reducido
    no se reproduce. El 80 % del recorrido es el umbral de confirmación (decisión de
    producto: el último 20 % es margen para el pulgar). Al soltar a partir de ahí, el botón
    termina de viajar hasta el extremo derecho y queda a 16 dp del borde con la flecha
    `primary`, con 192 dp de rastro al 50 % sobre la pista. Entonces el botón y el rastro
    se ocultan, la pista `primary` muestra el indicador de guardado y el texto «Saving
    session»; el mínimo es 1,2 s. El texto queda a la izquierda y el `M3ELoadingIndicator`
    a la derecha, dentro de una caja de layout de 84 dp: su caja interna de 106 dp (38:48)
    queda centrada, los 11 dp transparentes de cada lado no cuentan y el hueco
    texto-figura es 16 dp, igual que en Guardada. Al entrar en Guardada, la fila
    `Saving session` se desvanece primero (≈150 ms) y `Session saved` entra después
    (≈150–300 ms) con un desplazamiento vertical corto, sin solaparse con la fila de
    guardado. La píldora queda en `primary` con el sello Amanecer (`sunny` de la
    biblioteca de formas de M3, `onPrimary`) y el check en `primary`. El sol aterriza con
    la curva spatial fast de M3 (0.42, 1.67, 0.21, 0.90, 350 ms): escala de 0.5 a 1 y medio
    giro (−180° a 0°) con un pequeño overshoot. Empieza a aparecer a ≈75 ms, antes de que
    termine la salida del texto de guardado, para no dejar la píldora vacía. El check entra
    a ≈273 ms con la curva effects fast (0.31, 0.94, 0.34, 1.00, 150 ms). La píldora hace
    un beat de 1,5 % (1 → 1.015 → 1) durante 350 ms. La pausa es 1,2 s y vuelve el botón
    Sleep. La secuencia y el beat son decisiones de producto; las curvas son los fallbacks
    web de M3. Un descarte usa `error`/`onError`, «Session discarded» y el icono
    `M3EIcons.cancel_outlined` de 40 dp; un fallo, «Couldn't save the session» y
    `M3EIcons.error_outline_rounded`. En los tres resultados, la etiqueta y el icono
    (o el sol de 84 dp en el guardado) forman un grupo centrado con 16 dp entre ambos,
    y el icono o sol queda a la derecha del texto. `Saving session`, `Session saved`,
    `Session discarded` y `Couldn't save the session` comparten el estilo del botón
    Sleep: `titleLarge` emphasized con `Sleepy3Theme.brandTitle` (22/28, Google Sans
    Flex 900).
  - El control conserva el tamaño y la posición; el radio pasa de 68 dp a 28 dp y el
    relleno de `primary` a `error` en el descarte y el fallo. Una guarda de 400 ms ignora
    arrastres y toques después del cambio. El texto se ajusta con `FittedBox` al 200 % y
    cuando una cadena larga no cabe a 22 dp.
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
  - Filtros `Week` / `Month` / `3 months` / `Year` / `All` con `M3EChip` tipo filter:
    32 dp de alto, radio 8 dp y 8 dp entre chips. El activo añade un check leading,
    además del color, para no depender solo del color. Un `Wrap` absorbe el quinto chip
    sin romper el layout al 200 % de texto.
  - Hero `M3ECard` outlined (radio 12 dp, padding 16 dp): etiqueta `Average sleep` en
    `labelMedium`, valor en `displaySmall` emphasized con cifras tabulares, apoyo en
    `bodyMedium` (`Across {n} nights · {total} total`), línea de comparación con icono de
    subida/bajada y cobertura en `bodySmall`. `Show all` es un botón de texto. Sin datos
    muestra `—` y `No nights in this range`; nunca dibuja un 0 como noche real.
  - Card de métricas `M3ECard` outlined (radio 12 dp, padding 0): `Table` 2×2 en
    compacto y 4 columnas desde 600 dp, con divisores `outlineVariant` de 1 dp y 16 dp
    dentro de cada celda. Valores en `headlineSmall` emphasized con cifras tabulares,
    etiquetas `labelMedium` y apoyo `bodySmall`.
  - Gráficos: cada uno es una `M3ECard` outlined (radio 12 dp, padding 16 dp) con título
    `titleMedium` emphasized, apoyo `bodySmall` en `onSurfaceVariant`, un único
    `CustomPaint` de 180 dp y `RepaintBoundary`; la card `Sleep window` crece en alto con
    una fila por bucket. La leyenda usa muestras de línea/barra y texto, nunca solo color.
    M3 no publica un componente de gráficos: la altura, los anchos, el stagger y el radio
    de barra son decisiones de diseño de Sleepy3.
  - `Sleep duration`: barras `primary` con radio superior de 4 dp, ancho adaptativo entre
    4 y 28 dp; línea de objetivo `outline` de 1.5 dp con etiqueta `Goal 8h`; línea de
    media `tertiary` (o `onSurfaceVariant` si no llega a 3:1 sobre `surface`); grid
    `outlineVariant` de 1 dp al 60 %; noches sin datos como marca discontinua, nunca una
    barra a cero. El tooltip da el valor y el número de sesiones, y en buckets semanales
    o mensuales usa el tooltip rico con el rango y la media por noche.
  - `Sleep window`: una cápsula `primary` con extremos full por bucket, banda de
    mínimos/máximos `primaryContainer` al 20 %, línea de media `tertiary` y eje de 18:00
    a 12:00 con etiquetas `6 PM` / `12 AM` / `6 AM` / `12 PM` (o 18:00 / 00:00 / 06:00 /
    12:00 en 24 h). En rangos largos cada fila es un bucket semanal o mensual con la
    media y el rango, no una fila por noche.
  - `By weekday`: siete barras `primary` de lunes a domingo, con los días sin datos como
    hueco; el mejor día lleva la etiqueta `Best` y el tooltip indica cuántas noches
    sostienen la media.
  - Motion: `M3EMotion.expressiveSpatialDefault` para crecimiento, posición y morph, y
    `effectsDefault`/`effectsFast` para color y opacidad, sin overshoot en opacidad. El
    stagger de 16 ms por barra se usa solo en la primera entrada de `Sleep duration`; al
    cambiar de rango las barras hacen morph desde el valor actual, las nuevas empiezan a
    cero y las que desaparecen se desvanecen. Con `disableAnimations` se dibuja el estado
    final de inmediato, sin entrada, stagger ni morph.
  - Interacción: una sola zona de scrub por gráfico selecciona la barra más cercana con
    tap o arrastre; solo hay un tooltip a la vez y se cierra al soltar o tocar fuera. El
    tooltip plano es `inverseSurface` / `onInverseSurface`, 24 dp de alto, 8 dp de
    padding y 4 dp de separación; el rico usa `surfaceContainer` / `onSurfaceVariant` y
    radio 12 dp. La barra seleccionada escala 1.02 con spring espacial y un halo
    `primaryContainer` de 2 dp; hay un `selectionClick` háptico al cambiar de barra.
  - Accesibilidad de gráficos: cada canvas va dentro de `ExcludeSemantics` y un
    `Semantics` con un solo resumen hablado (rango, media, mejor y peor noche, noches
    bajo objetivo y noches sin datos). No se crean 30 tab stops: el historial sigue
    siendo la vista accesible noche a noche. Las etiquetas del eje se espacian más al
    200 % y el canvas mantiene su altura.
  - Encabezado de lista `History` en `titleMedium` emphasized.
  - Historial con una `M3ECard` filled por sesión, radio 20 dp (decisión de diseño: M3 usa
    `CornerMedium`, 12 dp) y padding 16 dp en `Week` o 12 dp en los demás rangos; gap 8 dp
    o 6 dp. La tarjeta destacada usa
    `primaryContainer` / `onPrimaryContainer`; las dos siguientes mezclan ese acento con
    `surfaceContainerHighest` al 2/3 y 1/3, y desde la cuarta todas usan
    `surfaceContainerHighest` / `onSurface`. El degradado empieza en la sesión destacada
    y es una decisión de diseño (M3 no tiene un rol de recencia); solo la destacada usa
    `onPrimaryContainer`. En `Week` la tarjeta tiene tres líneas: píldora del día con
    el `on*` de la tarjeta al 10 % y texto `on*` (decisión de diseño, no un rol M3),
    duración `headlineSmall` emphasized (24/32) con cifras tabulares y rango
    `bodyMedium`. En los demás rangos es de dos líneas: píldora `labelSmall` con el mismo
    tinte, duración `titleLarge` emphasized (22/28) y rango `bodySmall`, con el rango al
    final de la segunda línea.
    El anillo mide 44 dp con trazo de 4 dp en `Week` y 36 dp con trazo de 3 dp en los
    demás rangos, en `primary` sobre un track del 18–22 % del `on*`, con `bedtime`
    de 18/15 dp. La cápsula de origen comparte el stadium y el tinte del 10 % de la
    píldora del día; la flecha `open_in_new` mide 14 dp en `Week` y 12 dp en compacto
    (decisión de diseño) y el nombre usa `labelMedium` (12/16) o `labelSmall` (11/16). El
    chevron mide 20/18 dp. Todas las tarjetas son botones con etiqueta hablada y pista
    `Opens the session`; crecen con el texto del sistema y no usan alturas fijas. Las de
    solo lectura abren `Session` con la card `Read-only session` y los campos bloqueados.
    El objetivo táctil es de al menos 48 dp.
  - Panel de sesión adaptativo: pantalla completa por debajo del breakpoint compacto y
    diálogo básico por encima. Usa `M3EDatePicker`/`M3ETimePicker`. El hero es una
    `M3ECard` filled en `primaryContainer` con radio 20 dp (decisión de diseño) y padding
    16 dp: marca de
    objetivo de 56 dp, duración `headlineMedium` emphasized con cifras tabulares, línea
    del objetivo en `bodyMedium`, día de despertar en `bodySmall` y todo en
    `onPrimaryContainer`. Las secciones usan encabezado `titleMedium` emphasized;
    cada fila de fecha u hora lleva el valor como headline y un icono final
    (`event_outlined`/`schedule_outlined`). La fecha omite el año cuando es el actual.
    Errores inline en `bodySmall` con rol `error`, y una acción `Delete session`
    separada y de bajo énfasis. Respeta el formato de 24 h del sistema.
    Bajo `Woke up`, la card `Night context` es una `M3ECard` outlined con radio 12 dp,
    padding 16 dp y título `titleMedium` emphasized precedido por `insights_outlined` de
    20 dp. Cada lectura usa un icono de 20 dp (`arrow_upward`/`arrow_downward` para la
    duración, `bedtime` para acostarse, `wb_sunny` para despertar, `emoji_events` para el
    ranking y `groups` para la noche dividida) y texto `bodyMedium`; la nota de noche
    dividida usa `bodySmall` en `onSurfaceVariant`. Nunca usa el color como único
    indicador: el texto dice `later`, `earlier` u `on your average`. La misma card se
    muestra en solo lectura, debajo de los campos bloqueados.
  - La vista de solo lectura usa el mismo hero. La card `Read-only session` es una
    `M3ECard` filled en `surfaceContainerHighest`, con radio 12 dp y padding 16 dp. El
    candado `lock_outlined` de 20 dp va en `onSurfaceVariant` dentro de un círculo
    `surface` de 40 dp centrado verticalmente contra el texto; el titular
    `Read-only session` usa `titleMedium` emphasized en `onSurface` y el apoyo
    `bodyMedium` en `onSurfaceVariant`. La card va entre el hero y `Fell asleep`. Los
    campos no abren pickers y no muestran los iconos de calendario o reloj. En compacto
    el diálogo solo tiene la X; en mediano y expandido, una única acción de texto
    `Close`.
  - La lista y el resumen se reconstruyen desde el estado actualizado tras guardar o
    borrar; no se recarga el historial. El snackbar solo aparece para sincronización
    pendiente, permiso necesario o sesión borrada.
  - Sin datos, el empty state reutiliza `Sleepy3EmptyState` con icono, headline y apoyo.
- Pantalla Settings:
  - Título `Settings` en `headlineMedium` emphasized y apoyo en `bodyMedium`; márgenes
    laterales de 16 dp, y 24 dp desde 600 dp de ancho (decisión de layout).
  - Secciones `Appearance`, `Reminders`, `Sleep data`, `Google Health` y `About` con
    encabezado `titleMedium` emphasized y 8 dp hasta la lista.
  - Filas `M3EListItem` dentro de `M3EList` con radio exterior 16 dp, interior 4 dp y gap
    2 dp. Las filas crecen con el texto del sistema.
  - Las filas de interruptor (`Sleep reminder` y `Sleep in progress`) no usan `M3EListItem`:
    el item agrupado recorta la etiqueta a una línea y excluye la semántica de sus hijos,
    así que el interruptor desaparecería para TalkBack. Comparten
    `SettingsToggleRow`, con la misma superficie rellena de 16 dp, texto `bodyLarge` /
    `bodyMedium`, mínimo de 72 dp y un `M3ESwitch` de 32 × 52 dp con objetivo de 48 dp;
    la fila entera es el objetivo táctil y anuncia `toggled` al lector de pantalla. Las
    filas de hora y de aviso usan la misma composición con texto que envuelve, para que
    las etiquetas largas no se recorten al 200 %.
  - La fila `Theme` usa el supporting text para el valor actual (`System`, `Light` o
    `Dark`), de modo que el lector de pantalla lo anuncie como parte de la etiqueta. El
    diálogo de selección usa opciones cortas para caber al 200 % de texto.
  - La fila `Time format` usa el supporting text para `12-hour` o `24-hour` y reutiliza
    el mismo diálogo de selección. El formato elegido se aplica también a los selectores
    de hora.
  - La fila `Language` usa el supporting text para el idioma actual y abre un diálogo con
    `English` / `Español`, `Cancel` y `Apply`. El cambio se aplica al instante; el idioma
    elegido se persiste y no hay opción `System`.
  - `Sleep reminder` usa un interruptor M3 Expressive y supporting text con el estado:
    `Off` o `Every day at {time}`, con el formato 12/24 h compartido. Al activarlo
    aparece `Reminder time`, que abre `M3ETimePicker`. Si las notificaciones están
    bloqueadas, se añade la fila de aviso con chevron. `Sleep in progress` reutiliza la misma
    fila, con icono de notificaciones y claves de test `sleep-reminder-switch` y
    `sleep-status-switch` respectivamente.
  - A partir del 150 % de texto se retiran los iconos decorativos de las filas de
    `Settings` para que las etiquetas largas (`Importar`, `Privacidad`) no se recorten;
    los controles de selección (radio del diálogo de fuente) se mantienen.
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
- Copy de la interfaz en inglés (plantilla de `lib/l10n/app_en.arb`; la traducción vive en
  `app_es.arb` y no se duplica en los widgets):

| Elemento | Texto |
|---|---|
| Acción de dormir | `Sleep` |
| Acción de despertar | `Slide to wake` |
| Guardando | `Saving session` |
| Guardada | `Session saved` |
| Descartada | `Session discarded` |
| Fallo al guardar | `Couldn't save the session` |
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
| Filtros de Stats | `Week`, `Month`, `3 months`, `Year`, `All` |
| Resumen de Stats | `Average sleep` |
| Apoyo del hero | `Across {n} nights · {total} total`, `5 of 7 nights`, `X nights recorded` |
| Comparación del hero | `vs previous week: +18 min` |
| Métricas | `Goal hit rate`, `Schedule consistency`, `Sleep balance`, `Best streak` |
| Valores de métricas | `86%`, `±32 min`, `+1h 20m`, `4 nights`, `current 2` |
| Títulos de gráficos | `Sleep duration`, `Sleep window`, `By weekday` |
| Apoyos de gráficos | `Week · 5 nights recorded · Goal 8h`, `Bedtime to wake · Week`, `Average by wake day · Week` |
| Leyendas de gráficos | `Sleep`, `Goal 8h`, `Average`, `Bedtime to wake`, `Range` |
| Tooltips de gráficos | `Tue, Oct 20 · 7h 20m`, `Oct 14 – Oct 20 · 7h 5m avg` |
| Insights | `Insights`, `Best night`, `Shortest night`, `Average bedtime`, `Average wake`, `Bedtime varies by`, `Nights with more than one session`, `Distribution` |
| Distribución | `Under 6h`, `6–7h`, `7–8h`, `8–9h`, `9h+` |
| Días de la semana | `Mon`…`Sun`, `Best` |
| Sin noches en el rango | `No nights in this range` |
| Historial limitado en gráficos | `Last 30 days available` |
| Night context | `Night context`, `Not enough nights yet.`, `+12 min vs your 7-night average`, `Bedtime 22 min later`, `Wake 5 min earlier`, `Longest session in this range`, `2nd longest session in this range` |
| Mostrar todo el historial | `Show all` |
| Límite de historial en Stats | `Only the last 30 days are available` / `Allow full history in Google Health to see older sessions.` / `Allow full history` |
| Historial denegado desde el banner | `Google Health needs permission to read older sleep sessions.` |
| Descarga limitada al historial | `Only the last 30 days were downloaded.` |
| Encabezado de la lista | `History` |
| Cápsula de otra app | `{app}` / `Another app` |
| Etiqueta hablada de otra app | `Read-only, from {app}` |
| Pista de fila | `Opens the session` |
| Título del panel de sesión | `Session` |
| Card de solo lectura | `Read-only session`, `This session was created in {app}, so it can't be edited from Sleepy3.` |
| Solo lectura sin app resuelta | `This session was created in another app, so it can't be edited from Sleepy3.` |
| Copia descargada de Sleepy3 | `This session was downloaded from Google Health. Switch to Google Health to edit it.` |
| Copia descargada de otra app | `This session was created in {app}. Downloaded copies can't be edited in Local.` |
| Secciones del panel de sesión | `Fell asleep`, `Woke up` |
| Objetivo en el panel | `Goal met · {delta} over the 8h goal`, `Goal met`, `{delta} short of the 8h goal`, `Your 8h goal` |
| Día de despertar en el hero | `Woke {date}` |
| Acciones del panel de sesión | `Save`, `Cancel`, `Close`, `Delete session` |
| Aviso de Google Health | `This night is also in Google Health. Saving updates both copies.` / `This night is stored in Google Health. Saving updates the Health Connect record.` |
| Confirmación de borrado | `Delete session?`, `Delete`, `Cancel` |
| Errores de validación | `The wake time must be after the sleep time.`, `The sleep time cannot be in the future.`, `The wake time cannot be in the future.`, `This session overlaps another sleep session.`, `This session overlaps the session in progress.` |
| Descartar cambios | `Discard unsaved changes?`, `Keep editing`, `Discard` |
| Avisos tras guardar | `Saved. Google Health will update when it can.`, `Saved locally. Allow Google Health write access to sync it.` |
| Sesión borrada | `Session deleted.` |
| Stats sin historial | `No sleep history yet` |
| Apoyo sin historial | `Your nights will appear here after you wake up.` |
| Apoyo sin historial durmiendo | `Your first night will appear here when you wake up.` |
| Título de Settings | `Settings` |
| Apoyo de Settings | `Theme, reminders, sleep data and app info.` |
| Secciones de Settings | `Appearance`, `Reminders`, `Sleep data`, `Google Health`, `About` |
| Recordatorio | `Sleep reminder`; apoyo `Off` o `Every day at {time}` |
| Hora del recordatorio | `Reminder time` |
| Notificación de sueño | `Sleep in progress`; apoyo `Shows a live timer while you sleep.` / `Off` |
| Permiso de sueño denegado | `Allow notifications to show your sleep status.` / `Open settings` |
| Aviso de notificaciones | `Notifications are off` / `Allow Sleepy3 to send the notification.` |
| Permiso denegado | `Allow notifications to get the sleep reminder.` / `Open settings` |
| Error al programar | `Couldn't set the sleep reminder. Try again.` |
| Notificación | `Time to record your sleep` / `Open Sleepy3 and tap Sleep when you turn off the lights.` |
| Fila de tema | `Theme` |
| Modos de tema | `System`, `Light`, `Dark` |
| Fila de hora | `Time format` / `12-hour`, `24-hour` |
| Fila de idioma | `Language` / `English`, `Español` |
| Diálogo de idioma | `Language`, `English`, `Español`, `Cancel`, `Apply` |
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

### Marca y arranque

- Icono del launcher adaptativo: la marca sobre el fondo claro `#EFF4F9`, con capa
  monocroma para los iconos temáticos de Android 13+. El fondo del icono no cambia con el
  tema, para que se reconozca igual en el cajón de apps y en la ficha de la tienda.
  El primer plano dibuja la marca a 52 dp sobre el lienzo de 108 dp: como el launcher solo
  muestra 72 dp, ocupa el 72 % del alto visible y deja 10 dp de cuerpo arriba y abajo. El
  círculo seguro de 66 dp es el máximo, no el tamaño objetivo.
- Fondo de lanzamiento y splash:
  - El fondo nativo usa el color de cuerpo del tema (claro `#EFF4F9`, oscuro `#121318`)
    en `LaunchTheme`, `NormalTheme` y, desde Android 12, en
    `windowSplashScreenBackground`.
  - En Android 12+ `windowSplashScreenAnimatedIcon` apunta a `drawable*/launch_mark.png`:
    lienzo de 288 dp con la marca a 190 dp dentro del círculo seguro de 192 dp. La
    variante `drawable-night-*` usa `#C6CCF7`. Así el splash del sistema no reutiliza el
    icono adaptativo (sin placa blanca ni reescalado del PNG legacy).
  - `SplashGate` dibuja la misma marca. La intro espera a que el primer frame de Flutter
    esté rasterizado (en debug el splash nativo puede seguir en pantalla mientras se
    compila el primer frame; si arrancara antes, la animación terminaría detrás). Después
    la marca entra a 190 dp y baja a su tamaño de reposo (144 dp de caja, 132.5 dp
    visibles) en 550 ms; luego hay 200 ms de pausa y 250 ms de fundido. Total: 1000 ms.
  - 1.43×, 1000 ms y la secuencia son decisiones de diseño, no tokens M3. Las curvas son
    las de fallback web de M3 para los springs espacial y de efectos.
  - Con «reducir movimiento» activo no se muestra.
- El tema elegido se replica en el modo nocturno por aplicación de Android
  (`UiModeManager.setApplicationNightMode`, API 31+) al arrancar y al cambiarlo en
  Settings. Así el splash nativo del siguiente arranque en frío usa el mismo modo que la
  app, aunque el sistema esté en el modo contrario. En Android 9–11 no existe ese modo
  por aplicación y el splash nativo sigue al sistema.
- La carga real (base de datos, tema, fuente y versión) ocurre antes de `runApp`; el
  splash de Flutter es una intro de marca, no un bloqueo de carga. Si una lectura falla,
  la app arranca con el valor por defecto.
- Las fuentes de marca están en `assets/brand/`. `dart run tool/generate_brand_assets.dart`
  regenera el icono del launcher, las marcas del splash nativo y `Sleepy3-mark.png`. El
  banner `Sleepy3-rounded.png` es la cabecera del README.

---

## 5. Stack técnico

| Capa | Tecnología |
|---|---|
| UI | Flutter 3.47.x / Dart 3.13.x |
| Diseño | `material_ui` 1.7.0 + `material_3_expressive` 1.1.7 |
| Tipografía | Space Grotesk variable (UI) y Google Sans Flex instanciada (títulos), assets OFL |
| Fechas | `intl` 0.20 |
| Estado | Riverpod |
| Persistencia | Drift + SQLite (`drift_flutter`, `sqlite3`) |
| Info de la app | `package_info_plus` 10.x |
| Widget | `home_widget` + Jetpack Glance nativo |
| Salud | `health` 13.x sobre Health Connect `SleepSessionRecord` |
| Recordatorios | `flutter_local_notifications` 22.3.3, `timezone` 0.11, `flutter_timezone` 5.x |
| Background | WorkManager para Flutter (futuro) |
| Android | `minSdk` 28, `applicationId` `com.sleepy3.app` |

Notas:

- `material_ui` está fijado en **1.7.0**: la 1.8.0 introduce `RoundedPolygon`, que choca con
  `material_new_shapes` usado por `material_3_expressive` 1.1.7. No actualizar hasta que
  los paquetes sean compatibles.
- `flutter_local_notifications` está fijado en **22.3.3**: la 23 exige `compileSdk` 37 y
  AGP 9.1.1, mientras el proyecto usa 36 y 9.1.0. El recordatorio usa alarmas inexactas
  (`inexactAllowWhileIdle`) y no pide `SCHEDULE_EXACT_ALARM`.
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
│   ├── splash_gate.dart
│   └── navigation/
│       └── sleepy3_destination.dart
├── core/
│   ├── notifications/    # shared flutter_local_notifications plugin and tap routing
│   ├── theme/
│   ├── time/             # clock formatting, day/night rule and LocalDayBuilder
│   └── widgets/
├── l10n/                 # app_en.arb, app_es.arb, generated AppLocalizations and helpers
└── features/
    ├── sleep_tracking/
    │   ├── domain/         # sessions, durations, history, edit draft, store and notification contracts
    │   ├── data/           # Drift database, store and native notification presenter
    │   ├── application/    # controllers, edit service, notification sync and state
    │   └── presentation/   # home screen, header, clock, buttons and summary
    ├── stats/
    │   └── presentation/   # screen, chips, summary, history list and session editor
    ├── settings/
    │   ├── domain/         # theme, time format, language, app version and store contract
    │   ├── data/           # Drift-backed settings store
    │   ├── application/    # theme, time format and language controllers, providers
    │   └── presentation/   # settings screen, appearance dialogs and about list
    ├── health/
    │   ├── domain/         # gateway, source, history access, sync store, stored session and own-source helper
    │   ├── data/           # Health Connect gateway and Drift sync store
    │   ├── application/    # source, history, history-permission, sync, upload and copy
    │   └── presentation/   # copy dialogs, sync and history banners, source text
    ├── reminders/
    │   ├── domain/         # SleepReminder, next occurrence and scheduler contract
    │   ├── data/           # timezone-aware reminder scheduler
    │   ├── application/    # reminder controller and providers
    │   └── presentation/   # Reminders section and switch row
    └── widget/             # 0.3.0
assets/
├── brand/                 # fuentes del logo, marca del splash e iconos generados
└── fonts/                 # Space Grotesk, Google Sans Flex para títulos y licencias OFL
```

### Arranque

1. `main()` inicializa Flutter.
2. Abre `Sleepy3Database`.
3. Purga de una vez las sesiones cerradas locales fuera del rango registrable (menos de
   10 minutos o 24 horas o más) que nunca llegaron a Health Connect
   (`purgeUnrecordableSessions`); un fallo solo se registra y no bloquea el arranque.
4. Carga un `SleepSnapshot` con la sesión abierta y todas las sesiones cerradas,
   ordenadas de más antigua a más reciente.
5. Carga el modo de tema, el formato de hora, el idioma, la fuente de datos y el
   recordatorio de `preferences`, y la versión instalada con `package_info_plus`. Si no
   hay formato o idioma guardado, resuelve el valor del teléfono y lo persiste. Después
   replica el modo de tema en el modo nocturno por aplicación de Android (API 31+), para
   que el próximo arranque en frío resuelva el splash con el mismo modo.
6. Inyecta los stores, el snapshot, el tema inicial, el formato de hora, el idioma, la
   fuente, el recordatorio y la versión en `ProviderScope`.
7. Muestra el shell envuelto por `SplashGate`; la intro espera al primer frame
   rasterizado, reproduce el zoom de marca y se retira sobre la app ya construida. El
   fondo de lanzamiento nativo ya usaba el color de cuerpo del tema, así que el handoff
   no muestra un frame negro.

Si una lectura inicial falla, la app arranca con el valor por defecto (estado vacío,
tema `System`, formato del teléfono, idioma del teléfono o versión oculta) y registra el
error; no debe quedar bloqueada en el
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
- `SleepTrackingController.refreshHistory` relee sin vaciar `closedSessions` y devuelve
  `false` si la fuente falla; `reloadHistory` mantiene el vaciado y la tarjeta de carga
  para Retry, cambios de fuente y banners. `wake()` usa `refreshHistory` para conservar el
  resumen y la línea de sesión. En Home, el hueco de la tarjeta de resumen/carga tiene un
  alto fijo: una copia invisible de la tarjeta con la duración más larga lo reserva y la
  tarjeta visible lo llena, de modo que la columna centrada no se mueve. `StatsScreen`
  monta su propio overlay con `M3ELoadingIndicator` de 48 dp (38 dp activo), captura el
  pull con `OverscrollNotification`/`ScrollUpdateNotification`, desactiva el overscroll
  nativo y no transforma el contenido. El empty state comparte el mismo
  `CustomScrollView`.
- `SleepTrackingController.updateClosedSession` y `deleteClosedSession` pasan por
  `SleepSessionEditService` dentro de la misma cola serializada que el resto de escrituras.
  El servicio decide si va primero Health Connect o la fila local, devuelve un resultado
  explícito (`saved`, `savedPendingSync`, `deleted`, `permissionNeeded`, `failed`) y la
  acción se aplica a `closedSessions` por identidad (`localId` o `healthRecordId`) sin
  recargar el historial. `HealthSyncController.refreshPendingCount` se actualiza después.
- `SleepDataSourceController` valida disponibilidad y permisos antes de guardar
  `Google Health`; si falla, conserva `Local`.
- `HealthSyncController` mantiene el estado de conexión, la cola de pendientes y el
  último sync. `SleepCopyController` expone las tres acciones de copia y comparte el
  servicio con la UI. `HealthHistoryPermissionController` posee el permiso de historial
  (`unknown`, `authorized`, `denied`), comparte una sola petición concurrente y relee el
  estado al cargar el historial y al volver al primer plano.
- `ThemeModeController` es un `Notifier<AppThemeMode>`. Actualiza el estado al instante,
  serializa las escrituras y conserva la elección visible si una escritura falla.
- `TimeFormatController` es un `Notifier<AppTimeFormat>` con la misma actualización
  inmediata y cola de escritura. `main` lo carga antes del primer frame; si no hay valor
  guardado, resuelve el formato del teléfono y lo persiste para que quede fijo.
- `SleepReminderController` es un `Notifier<SleepReminderState>`. Serializa permisos,
  programación y cancelación en una sola cola para que un arranque, un cambio de hora y
  un cambio Sleep/Wake no dejen una alarma anterior armada. `SleepReminderScheduler` es
  la interfaz de plataforma; `LocalSleepReminderScheduler` usa `timezone` y
  `flutter_timezone` a través del `LocalNotifications` compartido, y `SleepReminder`
  calcula la próxima hora con aritmética de calendario. La lógica con reloj se prueba con
  horas fijas.
- `SleepingNotificationController` serializa la publicación y cancelación de la
  notificación de sueño en curso. `SleepingNotificationPresenter` es la interfaz;
  `NativeSleepingNotificationPresenter` delega el permiso en el `LocalNotifications`
  compartido e invoca el puente nativo `com.sleepy3.app/sleeping_notification`, que pinta
  la tarjeta con `RemoteViews`, cronómetro nativo, importancia baja y canal propio.
  `SleepingNotificationEnabledController` es un `Notifier<bool>` que persiste el
  interruptor; `sync` no publica nada cuando está apagado.
- `Sleepy3App` sincroniza el recordatorio al arrancar, al volver al primer plano, al
  cambiar `isSleeping` y al cambiar el idioma. Una sesión abierta lo cancela; despertar
  lo vuelve a armar. También sincroniza la notificación de sueño en curso al arrancar, al
  volver al primer plano, al cambiar la sesión abierta, el idioma o el formato horario. El
  toque de cualquiera de las dos notificaciones incrementa
  `notificationHomeRequestProvider` y `Sleepy3Shell` selecciona `Home`.
- `Sleepy3App` resuelve el brillo con el modo de tema y el brillo del sistema; mantiene
  `M3EMaterialApp.autoTheming` desactivado para usar los esquemas claro/oscuro propios.
  También envuelve la app en un `MediaQuery` con `alwaysUse24HourFormat` resuelto, de modo
  que todas las horas y los selectores compartan el ajuste sin leerlo en cada pantalla.
  `Sleepy3Theme` construye la paleta fija: anclas exactas de fondo y acento, y roles
  neutrales derivados de los pasos tonales de superficie de M3.

### Datos

- `SleepSessionStore` es la interfaz de persistencia. `updateSession` y `deleteSession`
  solo modifican filas `origin='local'`; las descargadas se rechazan. Al cargar, cada
  sesión local incluye `localId`, `isDownloaded`, `healthRecordId`,
  `healthClientRecordId` y `sourceId` para que el editor encuentre la fila sin comparar
  horas y pueda nombrar la app de origen.
- `DriftSleepSessionStore` es la implementación. Una sola consulta ordenada carga la
  sesión abierta y todo el historial cerrado; `SleepSnapshot.lastSession` es un getter.
- `SleepTrackingState` mantiene `closedSessions` completo de la fuente elegida. Home
  filtra los 3 días y `Stats` el rango elegido en memoria; la base de datos no se consulta
  desde la UI.
- `SleepHistoryRepository` tiene dos implementaciones: `LocalSleepHistoryRepository`
  (Drift) y `HealthConnectSleepHistoryRepository` (Health Connect). La segunda lee desde
  el epoch solo con `HealthHistoryAccess.authorized`; en caso contrario aplica
  `healthConnectHistoryLimit` (30 días) e incluye hasta el día siguiente para tolerar
  relojes desfasados. Además enriquece cada registro con `localId` y
  `healthClientRecordId` si existe una copia local; un fallo al leer esos metadatos no
  oculta el historial, y las filas escritas por la build actual siguen siendo editables por
  su UUID y su token real.
- `healthSleepSessionFromDataPoint` usa `sourceName` como paquete cuando el plugin deja
  `sourceId` vacío en Android, para que los registros propios se reconozcan.
- `sessionEditAccess` decide qué ofrece cada sesión: editar y borrar o nada.
  `isSleepy3HealthRecord` reconoce los paquetes release y debug de Sleepy3 para etiquetar
  su procedencia, pero la escritura exige `isHealthRecordOwnedBy`: el `sourceId` debe ser
  el paquete actual (`currentAppPackageProvider`, cargado desde `PackageInfo.packageName`).
  Un registro de la otra build es de solo lectura porque Health Connect solo deja modificarlo
  al paquete que lo escribió.
- `HealthConnectBridge` es un puente Android mínimo que lee `clientRecordId` y
  `clientRecordVersion` de un registro y borra un registro devolviendo `deleted`,
  `notFound`, `permission` o `failed`. El gateway reutiliza la escritura idempotente con la
  versión siguiente. No se usa para registros de otras apps ni de otro paquete.
- `AppInfoBridge` es un puente Android mínimo que resuelve el label de un paquete con
  `PackageManager`. `MethodChannelAppInfoGateway` lo cachea por paquete y devuelve null si
  la app no está instalada o el canal no responde; la card de solo lectura cae entonces a
  `another app`.
- `SleepingNotificationBridge` es el puente Android de la notificación de sueño. Crea el
  canal `sleep_status`, publica y cancela el id `1002` con una tarjeta `RemoteViews` y
  convierte la hora de inicio a la base de `Chronometer`; si el texto del sistema es grande
  o el layout falla, usa el layout estándar. `MainActivity.onNewIntent` reenvía el toque a
  Dart para volver a `Home`.
- `HealthSyncStore` y `DriftHealthSyncStore` gestionan pendientes, UUID descargados,
  versiones estables y deduplicación sobre la misma base. `loadPendingUpdates` devuelve
  solo actualizaciones de registros ya existentes; `loadLocalSessionsWithHealthRecordId`
  alimenta el enriquecimiento del historial de Google Health. `updateDownloadedSource`
  rellena el paquete de origen de una copia descargada sin tocar sus horas.
- `SettingsStore` es la interfaz de preferencias y `DriftSettingsStore` su implementación.
  Usa la tabla `preferences` de la misma base; no hay `shared_preferences`. Guarda
  `theme_mode`, `time_format`, `language` y `sleep_data_source`.
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
| `health_client_record_id` | TEXT | Id estable usado para actualizar el mismo registro |
| `health_record_version` | INTEGER | Última versión enviada a Health Connect; por defecto 0 |
| `health_synced_at_millis` | INTEGER | Última subida o descarga correcta |
| `health_sync_skipped` | INTEGER | 0/1; sesión no elegible (por ejemplo, duración cero) |
| `origin` | TEXT | `local` o `healthConnect`; por defecto `local` |
| `source_id` | TEXT | Paquete de la app que escribió una copia descargada; null en filas locales |

- `schemaVersion = 5`.
- Base: `sleepy3.sqlite` en el directorio de documentos de la app.
- La migración v2 → v3 añade `health_record_id`, `health_synced_at_millis`,
  `health_sync_skipped` y `origin`, con defaults y el índice único de `health_record_id`;
  las filas existentes quedan locales, pendientes y elegibles.
- La migración v3 → v4 añade `health_client_record_id` y `health_record_version`.
  Rellena `health_client_record_id = 'sleepy3-<started_at_millis>'` en las filas
  `origin='local'` y pone `health_record_version = 1` en las filas que ya tienen
  `health_record_id`. Las descargadas conservan `health_client_record_id` nulo.
- La migración v4 → v5 añade `source_id` para el paquete de origen de una copia
  descargada. Las filas existentes quedan con `source_id` nulo y se rellenan en la
  siguiente importación.
- `health_client_record_id` es estable aunque cambien las horas: permite actualizar el
  mismo registro de Health Connect sin duplicarlo. `health_record_version` solo crece; un
  reintento usa la versión siguiente y `markUploadAttempt` la persiste antes de escribir.
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
- Clave `time_format` con valores `twelveHour` o `twentyFourHour`; un valor ausente o
  desconocido se resuelve con el formato del teléfono en el primer arranque.
- Clave `language` con valores `english` o `spanish`; un valor ausente o desconocido se
  resuelve con el idioma del teléfono en el primer arranque.
- Clave `sleep_data_source` con valores `local` o `healthConnect`; un valor ausente o
  desconocido se interpreta como `local`.
- Clave `sleep_reminder_enabled` con `true` o `false`; ausente equivale a desactivado.
- Clave `sleep_reminder_time` con `HH:mm` entre `00:00` y `23:59`; ausente o inválida
  equivale a `22:00`.
- Clave `sleep_notification_permission_asked` con `true` o `false`; ausente equivale a
  `false`. Solo evita repetir el diálogo de permiso del primer Sleep.
- Clave `sleep_status_notification_enabled` con `true` o `false`; ausente equivale a
  `true`. Controla el interruptor `Sleep in progress` de Ajustes.
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
- Solo las filas `origin='local'` se editan o borran en modo `Local`; las descargadas son
  copias de solo lectura.
- Editar una sesión sincronizada conserva su `health_client_record_id`, incrementa
  `health_record_version` y la deja pendiente hasta que Health Connect confirma. Un fallo
  no crea un registro nuevo en el siguiente intento.
- En `Google Health` solo se modifican registros escritos por Sleepy3; los de otras apps
  son de solo lectura.
- La sesión abierta no se edita ni se borra desde `Stats`; primero hay que despertar.

### Privacidad

- No hay backend propio.
- En `Local`, la base local es la fuente de verdad y Health Connect no se lee ni se
  escribe automáticamente.
- En `Google Health`, Sleepy3 lee y escribe `SleepSessionRecord` en Health Connect con
  permiso explícito. La copia local se mantiene como red de seguridad. Editar o borrar
  desde Stats actualiza o elimina el registro de Health Connect de Sleepy3; los registros
  de otras apps nunca se modifican.
- En `Local`, editar una sesión que ya está en Health Connect también actualiza ese mismo
  registro con permiso de escritura. Si el permiso falta o la escritura falla, la copia
  local queda pendiente y se reintenta al abrir o volver a la app.
- El historial anterior a 30 días solo se lee si el usuario concede
  `READ_HEALTH_DATA_HISTORY`; sin él, la app aplica el límite localmente y lo explica en
  Stats y en el resultado de `Import`.
- Sleepy3 no accede a la nube de Google Health ni a una API cloud; solo al proveedor de
  Health Connect del dispositivo.
- El recordatorio se programa en el propio teléfono. La notificación no contiene horas ni
  datos de sueño, solo la invitación a abrir Sleepy3.
- Denegar un permiso nunca bloquea el registro local.

---

## 8. Widget de pantalla de inicio (0.3.0)

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
  - Editar una sesión que ya está en Health Connect actualiza la copia local primero y
    después el mismo registro con su `clientRecordId` y una versión mayor. Si falla, la
    fila queda pendiente y se reintenta; el reintento automático de `Local` solo procesa
    actualizaciones, nunca altas nuevas.
  - Borrar una sesión con registro borra primero en Health Connect; si falla, conserva la
    copia local. Una sesión sin registro se borra solo de Drift.
- Fuente `Google Health`:
  - Home y Stats leen todas las sesiones `SLEEP_SESSION` de Health Connect, de cualquier
    app, ordenadas de más antigua a más reciente.
  - `Wake` cierra la fila local y escribe el registro en Health Connect con
    `clientRecordId = sleepy3-<startedAtMillis>` y `clientRecordVersion = 1`.
  - Si la escritura falla, la fila local queda pendiente y el reintento ocurre al abrir o
    volver a la app. El banner de Home/Stats muestra el recuento y `Retry`.
  - Una sesión pendiente no aparece en las gráficas de Google Health hasta que Health
    Connect confirma la escritura.
  - Editar un registro propio escribe primero en Health Connect y, si confirma, actualiza
    la copia local (si existe) y la lista visible. Si falla, el editor sigue abierto. El
    `clientRecordId` y la versión se leen siempre del puente nativo, que verifica el paquete
    actual; así una fila migrada de una versión anterior no crea un duplicado. La sesión
    devuelta al controlador conserva el UUID nuevo que asigna la escritura.
  - Borrar un registro propio lo elimina de Health Connect y después de la copia local.
    Se intenta primero el UUID actual, después el `clientRecordId` guardado y, si ambos
    fallan por inexistentes, se relee el registro por las horas exactas y se borra su UUID
    actual. Si ya no existe ningún registro propio en ese intervalo, se considera borrado y
    se limpia la copia local. Un fallo de permiso conserva la copia y el editor ofrece
    **Allow** para solicitarlo y reintentar. Los registros de otras apps y los de la otra
    build de Sleepy3 son de solo lectura.
- Escritura idempotente: el `clientRecordId` estable y la versión creciente evitan
  duplicados al reintentar o actualizar una sesión editada.
- El historial de Google Health adjunta `localId` y `healthClientRecordId` desde la copia
  local. Si esa lectura falla, el historial se muestra igualmente; las filas propias de
  esta build siguen siendo editables por su UUID y su token real.
- Sesiones fuera del rango registrable (menos de 10 minutos o 24 horas o más): la subida y
  las copias las marcan `health_sync_skipped` y no las escriben, porque Health Connect las
  rechaza; en Google Health el Wake descarta antes la sesión corta y, si la larga se
  arregla moviendo su inicio, se sube ya dentro del rango. Las filas locales fuera de
  rango que nunca llegaron a Health Connect se purgan al arrancar; una fila ya sincronizada
  puede corregirse con el editor y el reintento la vuelve a subir con la duración válida.
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
  - `READ_HEALTH_DATA_HISTORY` se pide al elegir `3 months`, `Year` o `All` en Stats o al
    iniciar `Import`.
  - Con el permiso, las lecturas empiezan en el epoch; sin él, en los últimos 30 días.
  - Stats muestra `Only the last 30 days are available`, `Allow full history` y el apoyo
    `Last 30 days available` en los gráficos cuando el permiso falta; `Import` avisa en el
    resultado de que solo bajó 30 días.
  - El permiso se comprueba de nuevo al cargar el historial y al volver del segundo plano.
- Si el usuario deniega permisos o Health Connect no está disponible, no se bloquea el
  registro local; Settings explica el estado y ofrece `Connect` o `Install`.
- La publicación en Play Console requiere la declaración de Health Connect.
- Tests cubiertos: permiso de sueño e historial concedidos y denegados, API no disponible,
  actualización requerida, reintento idempotente, fallo parcial, deduplicación, límite de
  30 días, acciones de copia, edición/borrado en Local y Google Health, versiones
  crecientes, enriquecimiento del historial, reintentos de solo actualizaciones en Local
  y los límites de duración (descarte de Wake, corrección del inicio, editor y subida).

---

## 10. Calidad y pruebas

### Comandos

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter run
dart format .
dart run build_runner build
dart run tool/generate_brand_assets.dart
```

### Cobertura actual

- Máquina de estados: inicio, Sleep, Wake, doble toque, clock skew, duración mínima y
  máxima (descarte de Wake, diálogo y corrección del inicio de una sesión larga).
- Persistencia: alta, cierre, restauración, sesiones abiertas duplicadas, carga de todo
  el historial cerrado, descarte de la sesión abierta, cambio del inicio de la sesión
  abierta y purga de filas locales fuera de rango no sincronizadas al arrancar.
- UI: estado inicial, botón Sleep, deslizamiento Wake, duración en vivo (incluido el
  primer minuto), botón viajero + rastro al 50 %, umbral del 80 % con recorrido completo al
  soltar, flecha visible al final, guardado mínimo (1,2 s) con la figura de 84 dp a la
  derecha y hueco de 16 dp,
  sello Amanecer `sunny` + check, handoff de guardado (salida de `Saving session`,
  aterrizaje del sello y entrada del texto/check), beat de 1,5 %, descarte
  (`cancel_outlined`)/fallo (`error_outline_rounded`), guarda de
  doble gesto, pulsación 28 → 16 dp, velo de noche, aterrizaje de la luna al dormir,
  semántica, reduce motion, restauración y layout a 360 dp/200 %.
- Cabecera, reloj en vivo y línea de sesión: formato 12/24 h, límites día/noche, timer,
  cambio de fecha y layout con texto al 200 %.
- Resumen de 3 días: agrupación por día de despertar, sesiones que cruzan medianoche,
  suma por día, media sobre días con datos, cambio de fecha, DST, estado vacío, límite
  del 100 % y semántica.
- Stats: cinco rangos (`Week`, `Month`, `3 months`, `Year`, `All`), agrupación por día,
  ventanas exactas, varias sesiones por día, sesiones abiertas y futuras excluidas, cambio
  de fecha, DST, `Show all`, 12/24 h, semántica, layout a 360 dp y 600 dp con texto al
  200 %, claro/oscuro, español, densidad compacta en `Month`/`3 months`/`Year`/`All` y
  `LocalDayBuilder` al pasar medianoche o volver del segundo plano.
- Insights: media, mediana, cobertura, balance, rachas actual y mejor, objetivo exacto a
  8 h, media y desviación circulares, weekday sin datos, bandas de duración, comparación
  con el periodo anterior y su caso de cobertura insuficiente, buckets diarios, semanales
  y mensuales, `All` adaptativo, DST en Europe/Madrid y duraciones negativas.
- Gráficos: duración, ventana de sueño y día de la semana en los cinco rangos, huecos sin
  barras a cero, tooltip plano y rico, una sola zona de scrub, resumen hablado, morph al
  cambiar de rango, reduced motion, texto al 200 %, ventana de 600 dp y español.
- Night context: comparación con las 7 noches anteriores, caso de menos de 2 noches,
  ranking dentro del rango, noche dividida, editor y solo lectura, y texto al 200 %.
- Stats editable: todas las tarjetas son botones, sin icono de edición; las de solo lectura
  abren `Session` con la card de la app y campos bloqueados, editor adaptativo,
  guardado sin cambios, cambio de fecha y hora, validación inline (incluidos los límites
  de duración), descarte, 24 h, 200 % de texto, borrado con confirmación, empty state tras
  borrar la última sesión y actualización del resumen sin recargar.
- Edición y borrado: `updateSession`/`deleteSession` de Drift, rechazo de descargadas,
  permisos por fuente, actualización del mismo registro de Health Connect, lectura del
  token de escritura nativo, reintentos pendientes, resultados explícitos, filas propias
  de Google Health con y sin copia local, registros de otras apps de solo lectura y
  migración v5 con `source_id`.
- Solo lectura: app label por `AppInfoBridge`, fallback a `another app`, campos sin
  pickers ni iconos, sin `Save`/`Delete`, cierre con X o `Close` y copias descargadas
  con y sin `source_id`.
- Stats en Google Health: `3 months`, `Year` y `All` piden historial, una concesión
  recarga el historial completo, una denegación mantiene los 30 días con el banner
  `Only the last 30 days are available`, el apoyo `Last 30 days available` en los
  gráficos y `Allow full history`, que vuelve a pedir el permiso.
- Pull-to-refresh de Stats: el loader de 48 dp aparece y se retrae, la lista no se vacía,
  Google Health reintenta pendientes antes de leer, Local no sube altas, un fallo conserva
  las filas y muestra el snackbar, el empty state también se puede tirar y el layout aguanta
  el 200 % de texto.
- Settings: tema por defecto y persistido, diálogo de selección con `Cancel`/`Apply`,
  resolución `System`/`Light`/`Dark`, formato `12-hour`/`24-hour` por defecto y persistido,
  idioma `English`/`Español` sin opción `System` (el primer arranque resuelve y guarda el
  del teléfono), su aplicación a reloj, historial y selectores de hora, fuente
  `Local`/`Google Health`, diálogo de fuente, estado de conexión, `Connect`/`Install`,
  `Import`/`Sync`/`Add`, primer cambio con aviso de copia, permiso denegado, versión
  oculta si no está disponible, página de licencias, semántica, migraciones v1→v2, v2→v3 y
  v3→v4, y layout a 360 dp con texto al 200 %.
- Recordatorios: valor por defecto desactivado a las 22:00, ida y vuelta en `preferences`,
  hora malformada, permiso concedido/denegado, programación/cancelación, cambio de hora,
  pausa mientras se duerme, notificaciones bloqueadas, copy en inglés/español, próxima
  ocurrencia con reloj fijo y layout de la sección al 200 %.
- Notificación de sueño: tarjeta `RemoteViews` con cronómetro grande, fallback estándar con
  texto grande, importancia baja, publicación al dormir, cancelación al despertar,
  actualización al retimar o cambiar idioma/formato, permiso pedido una sola vez y copy en
  inglés/español. El puente se cubre con un test del `MethodChannel`.
- Interruptor de notificación de sueño: activado por defecto, persistencia, cancelación al
  desactivar, permiso al activar, denegación con `Open settings`, independencia del
  recordatorio y layout al 200 %.
- Health Connect: disponibilidad, permisos de sueño e historial, lectura/escritura,
  cola de pendientes, reintento idempotente, banner, sesiones omitidas, acciones de copia,
  deduplicación por UUID y horas exactas, fallo parcial, protección de filas locales,
  límite de 30 días y recarga al conceder el historial.
- Localización: paridad de claves ARB, resolución del idioma del sistema, cambio desde
  `Settings`, pantallas y editor en español, fechas, horas y duraciones localizadas, y
  layout a 360 dp con texto al 200 %.
- Enriquecimiento del historial de Google Health con la copia local y fallo tolerado al
  leer esos metadatos.
- Tema: paleta de marca fija (claro/oscuro), roles M3, contraste, tipografía Space
  Grotesk y los títulos en Google Sans Flex instanciada.
- Splash: overlay de marca sobre el shell, se retira al terminar la animación y se omite
  con reducir movimiento.
- Build Android debug y release correctos.

### Cobertura pendiente

- Widget nativo: taps, cola de pendientes y reconciliación.
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
- Pantalla principal con el botón Sleep y el deslizamiento Wake.
- Tema M3 Expressive fijo con la paleta de marca, Space Grotesk empaquetada y los títulos
  en Google Sans Flex instanciada.
- Persistencia Drift y restauración de sesión abierta.
- Cabecera con chip día/noche, reloj en vivo con segundos y línea de sesión.
- Resumen de los últimos 3 días con datos reales, media y barras contra una meta de 8 h.
- Pantalla `Stats` con dashboard de cinco rangos (`Week`, `Month`, `3 months`, `Year`,
  `All`), hero con media, total, comparación y cobertura, card de métricas, gráficos de
  duración, ventana de sueño y día de la semana, card de insights y una fila por sesión.
  Todas las filas abren la sesión: el editor adaptativo permite cambiar fecha y hora o
  borrar; las sesiones de otras apps y las copias descargadas abren una vista de solo
  lectura con la card de la app de origen. En `Google Health` solo se modifican los
  registros de Sleepy3.
- Pantalla `Settings` con tema `System`/`Light`/`Dark` persistido, formato de hora
  `12-hour`/`24-hour` persistido y aplicado a toda la app, idioma `English`/`Español`
  persistido (resuelto del sistema en el primer arranque, sin opción `System`), fuente de
  datos `Local`/`Google Health`, estado de Google Health, acciones de copia y `About` con
  privacidad, versión y licencias.
- Recordatorio nocturno opcional, desactivado por defecto a las 22:00, con hora elegida,
  permiso de notificaciones contextual, pausa mientras hay una sesión abierta, retorno a
  `Home` al tocar la notificación y aviso cuando Android bloquea las notificaciones.
- Notificación de sueño en curso silenciosa y no descartable, con tarjeta nativa y
  cronómetro grande, objetivo de 8 h y hora meta, fallback al layout estándar con texto
  grande, que se publica al dormir y se cancela al despertar. Se puede desactivar desde
  Ajustes con el interruptor `Sleep in progress`, activado por defecto.
- Health Connect: permisos de sueño e historial, lectura y escritura, cola de pendientes,
  reintento al abrir o volver a la app, banner de pendientes, acciones
  `Import`/`Sync`/`Add`, actualización del mismo registro tras una edición, borrado
  propagado y fallback de 30 días en los rangos largos de Stats.
- Builds debug (`com.sleepy3.app.debug`) y release firmada que conviven en el dispositivo.
- Icono de launcher adaptativo con capa monocroma y splash de marca con zoom out, en
  claro y oscuro.
- Releases estables manuales bajo demanda (`minor`, `patch` o `exact`), con versionado,
  firma y notas; sin publicaciones automáticas desde `dev` o `main`.
- Prueba manual del APK release en el dispositivo del maintainer, con Health Connect y
  Google Health, incluida la edición y el borrado de sesiones.
- Primera release estable 0.1.0, sin widget. La 0.1.6 añade el dock glass, la tipografía
  nueva y los detalles de solo lectura; la 0.1.7 añade el historial tonal, las marcas de
  objetivo y el panel de sesión; la 0.2.0 añade la acción única en Home, el pull-to-refresh,
  el alta manual, la animación de la marca de objetivo y la propiedad por build en Health
  Connect; la 0.2.1 añade la interfaz en inglés y español y el formato de hora 12/24; la
  0.2.2 añade el recordatorio nocturno, el deslizamiento para despertar y la duración en
  vivo. Ninguna incluye el widget.
- Stats avanzadas en `feat/stats-charts`: cinco rangos, hero y métricas, gráficos M3 de
  duración, ventana y día de la semana, insights y `Night context` por sesión. Pendiente
  de validación en dispositivo y release.
- Tests de estado, persistencia y UI.

### Siguiente

1. Widget de pantalla de inicio con Glance y `home_widget` (0.3.0).
2. Validación en dispositivo y release de las Stats avanzadas.

---

## 12. Decisiones abiertas

- Si el widget mostrará la duración en vivo o solo el estado.
- Si los reintentos pasarán a WorkManager en segundo plano o seguirán al abrir/volver a
  la app.
- Si `Import` recordará una denegación del permiso de historial para no volver a pedirla
  en cada intento hasta que el usuario la reactive.
