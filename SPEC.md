# Sleepy3 — Especificación de producto y técnica

**Proyecto:** Sleepy3
**Plataforma:** Android
**Stack principal:** Flutter + Material 3 Expressive
**Estado:** migración a Flutter en curso; la pantalla principal y la persistencia local ya funcionan.

---

## 1. Flujo de trabajo y releases

### Ramas

- Todo el trabajo nuevo se hace en la rama **`dev`**. `main` permanece estable.
- El merge a `main` y los tags se hacen **solo cuando el usuario lo pide**, después de
  verificar el bloque o la funcionalidad en su máquina.
- El trabajo no se queda solo en local: cuando el usuario dice «Haz los commits», se
  commitea **y se sube a `dev`**.

### Forma de trabajo

- **Paso a paso:** no generar toda la app de golpe. Esperar a que el usuario pida un módulo
  o cambio concreto. Al terminar, indicar qué debe probar el usuario.
- **Aviso previo:** el agente no commitea ni hace push por iniciativa propia. Propone el
  mensaje, espera el OK y recién entonces ejecuta.
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

- El usuario decide la versión (major/minor/patch a su criterio).
- El tag `vX.Y.Z` se corta desde `main`.
- **GitHub Actions está planificado, no implementado todavía.** Cuando exista
  `.github/workflows/release.yml`, compilará el APK, publicará la release con notas
  autogeneradas desde los commits convencionales desde el tag anterior y adjuntará el
  instalador. El tag será la fuente de verdad de la versión.
- Mientras el workflow no exista, la release se prepara y publica manualmente.
- Las notas curadas **no viven en el repo**: `release-notes/` está en `.gitignore` y solo
  existe en local. Después de publicar, se aplican con:

```bash
gh release edit vX.Y.Z --notes-file release-notes/vX.Y.Z.md
```

- Título de la release: `vX.Y.Z - The <Tema> Update`, donde `<Tema>` resume en inglés lo
  más importante (Title Case; siempre termina en `Update`). La fuente es la primera línea
  de `release-notes/vX.Y.Z.md`, un comentario HTML oculto:

```html
<!-- title: vX.Y.Z - The <Tema> Update -->
```

- Título por defecto del CI planificado: `Sleepy3 vX.Y.Z`.
- Estilo de las notas: inglés, emojis en los títulos de sección, contexto breve, una
  sección destacada y `## ✨ What's new` con el resto. Instalación, datos, requisitos y
  actualización viven en el `README.md`, no en las notas.
- El cuerpo publicado en GitHub debe coincidir con `release-notes/vX.Y.Z.md`.

---

## 2. Producto

Sleepy3 es una app Android de registro de sueño con fricción cero.

- Dos acciones grandes: **Sleep** y **Wake**. Sin formularios, sin cuentas, sin onboarding
  obligatorio.
- Guarda la hora exacta de inicio y fin de cada sesión.
- Los datos son locales por defecto. No hay backend ni nube propia.
- Health Connect es opcional y se usará para sincronizar `SleepSessionRecord`.
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
- Al arrancar la app se restaura la sesión abierta y la última sesión cerrada.
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

### 3.2 Navegación

- Barra de navegación M3 flexible (`M3ENavigationBar`, 64 dp) con tres destinos de
  igual importancia: `Home`, `Stats` y `Settings`.
- `Home` es el destino inicial. `Stats` y `Settings` son placeholders con un empty
  state M3 (icono, headline y texto de apoyo) hasta que se diseñe su contenido.
- El destino activo usa icono relleno, etiqueta en negrita y la píldora de selección;
  los inactivos usan icono outline.
- Un `IndexedStack` conserva el estado de cada pestaña al cambiar de destino.
- Atrás desde `Stats` o `Settings` vuelve a `Home`; atrás desde `Home` sale de la app.

### 3.3 Historial (planificado)

- Lista de sesiones recientes, ordenadas de más nueva a más vieja.
- Resumen de los últimos 3 días.
- Cada fila muestra inicio, fin y duración.
- Sin edición en la primera versión.
- La pestaña `Stats` mostrará este historial cuando se diseñe.

### 3.4 Widget de pantalla de inicio (planificado)

- Dos acciones: **Sleep** y **Wake**.
- El toque registra la hora sin abrir la app.
- Los eventos se escriben en una cola de pendientes.
- La app reconcilia la cola al abrirse o volver al primer plano.
- El widget refleja el estado actual (despierto/durmiendo) con los roles del tema M3.

### 3.5 Health Connect (planificado)

- Sincronizar cada sesión cerrada como `SleepSessionRecord`.
- Pedir permisos en el momento adecuado, no en el primer arranque.
- Si Health Connect no está disponible o el permiso se deniega, la app sigue funcionando
  localmente.
- Reintentar fallos transitorios con WorkManager.
- Evitar duplicados al reintentar.

### 3.6 Accesibilidad

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
- El modo sigue al sistema (claro/oscuro); no hay selector manual por ahora.
- Tipografía **Roboto Flex variable** empaquetada como asset (`assets/fonts/`, OFL).
  Se usan los tamaños, pesos y tracking de la escala M3; no se usan pesos 850/950.
- Mapeo tipográfico:
  - reloj: `displayLarge` emphasized, con cifras tabulares;
  - AM/PM: `titleMedium`;
  - marca: `headlineLarge` emphasized;
  - fecha y copy de apoyo: `bodyMedium` (la línea de sesión, emphasized);
  - chip día/noche: `labelMedium`;
  - cabecera y tarjeta de resumen: `titleMedium`, `labelMedium`, `bodyMedium`.
- La ilustración de luna/sol del prototipo no forma parte de la UI.
- Navegación:
  - Barra M3 flexible de 64 dp, a todo el ancho, con `surfaceContainer` y sin borde
    ni sombra.
  - Tres destinos: `Home`, `Stats` y `Settings`. El activo usa la píldora de selección
    y un icono relleno; los inactivos, icono outline.
  - `Stats` y `Settings` muestran un empty state M3 hasta que se diseñen.
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
  - Dos botones M3E grandes, de 96 dp de alto, con icono y etiqueta.
  - En pantallas angostas o con texto grande, los botones se apilan.
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
| Destinos de navegación | `Home`, `Stats`, `Settings` |

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
| Widget | `home_widget` + Jetpack Glance nativo |
| Salud | Health Connect `SleepSessionRecord` |
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
│   ├── time/             # clock formatting and day/night rule
│   └── widgets/
└── features/
    ├── sleep_tracking/
    │   ├── domain/
    │   ├── data/
    │   ├── application/
    │   └── presentation/   # home screen, header, clock and buttons
    ├── stats/
    │   └── presentation/   # placeholder
    ├── settings/
    │   └── presentation/   # placeholder
    ├── health/             # planificado
    └── widget/             # planificado
```

### Arranque

1. `main()` inicializa Flutter.
2. Abre `Sleepy3Database`.
3. Carga un `SleepSnapshot` con la sesión abierta y la última cerrada.
4. Inyecta el store y el snapshot en `ProviderScope`.
5. Recién entonces muestra la app.

Si la lectura inicial falla, la app arranca con estado vacío y registra el error; no debe
quedar bloqueada en el splash.

### Estado

- `SleepTrackingController` es un `Notifier<SleepTrackingState>`.
- Actualiza el estado en memoria primero, para que los botones respondan al instante.
- Después encola la escritura en un `Future` serializado.
- La UI escucha el estado; no lee la base de datos directamente.
- El reloj se inyecta con `sleepClockProvider`; la lógica de dominio no llama a
  `DateTime.now()`.

### Datos

- `SleepSessionStore` es la interfaz de persistencia.
- `DriftSleepSessionStore` es la implementación.
- Los tests usan `FakeSleepSessionStore` o una base Drift en memoria.

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

- `schemaVersion = 1`.
- Base: `sleepy3.sqlite` en el directorio de documentos de la app.
- Al agregar o cambiar columnas, subir `schemaVersion` y escribir una migración.
- El código generado (`sleepy3_database.g.dart`) se commitea.
- Después de cambiar el esquema:

```bash
dart run build_runner build
```

### Invariantes

- Como máximo una sesión abierta.
- `Wake` cierra todas las filas abiertas; si hubo un crash y quedaron duplicadas, se
  reparan.
- Una sesión abierta sobrevive al cierre de la app.
- La duración nunca es negativa.
- Los timestamps se guardan en milisegundos para conservar la hora local exacta.

### Privacidad

- No hay backend propio.
- La base local es la fuente de verdad.
- Health Connect es opcional y solo se usa con permiso explícito.

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

## 9. Health Connect (planificado)

- API: `SleepSessionRecord`.
- Requiere Android 9 (API 28) o superior.
- En Android 13 o inferior, Health Connect debe estar instalado.
- Flujo:
  1. Al cerrar una sesión, construir el registro con inicio y fin.
  2. Escribirlo en Health Connect.
  3. Si falla por un error transitorio, encolar un reintento con WorkManager.
  4. Reintentar de forma idempotente para no duplicar registros.
- Si el usuario deniega permisos, no bloquear el registro local.
- La publicación en Play Console requiere la declaración de Health Connect.
- Tests pendientes: permiso concedido, denegado, API no disponible y reintento.

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
- Persistencia: alta, cierre, restauración, sesiones abiertas duplicadas.
- UI: estado inicial, cambio Sleep/Wake, restauración y layout a 360 dp.
- Cabecera, reloj en vivo y línea de sesión: formato 12/24 h, límites día/noche, timer,
  cambio de fecha y layout con texto al 200 %.
- Tema: claro/oscuro desde la misma semilla, roles M3 y tipografía Roboto Flex.
- Build Android debug correcto.

### Cobertura pendiente

- Widget nativo: taps, cola de pendientes y reconciliación.
- Health Connect: permisos, sync, reintentos e idempotencia.
- Historial y resumen de 3 días.
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
- Tests de estado, persistencia y UI.

### Siguiente

1. Widget de pantalla de inicio con Glance y `home_widget`.
2. Health Connect y reintentos.
3. Historial y resumen de 3 días.
4. Workflow de release en GitHub Actions.
5. Pulido de motion y accesibilidad.

---

## 12. Decisiones abiertas

- Formato exacto del historial (lista simple vs. tarjetas).
- Si el widget mostrará la duración en vivo o solo el estado.
- Estrategia de reintentos de Health Connect (cantidad y backoff).
- Si se agregará localización completa después de la primera release en inglés.
