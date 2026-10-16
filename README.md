# Sleepy3

Registro de sueño minimalista para Android con fricción cero: dos botones, sin formularios.

![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-2.0.20-7F52FF?logo=kotlin&logoColor=white)
![Compose](https://img.shields.io/badge/Jetpack_Compose-Material3-4285F4?logo=jetpackcompose&logoColor=white)
![Min SDK](https://img.shields.io/badge/minSdk-26-blue)
![Target SDK](https://img.shields.io/badge/targetSdk-34-blue)

> Estado actual: Módulo 1 (botones Dormir / Despertar en memoria). Sin persistencia todavía.

## Qué es

Sleepy3 permite registrar la hora exacta en la que te duermes y te despiertas con dos botones grandes, accesibles desde la app principal y (próximamente) desde un widget en la pantalla de inicio.

Los datos se guardarán localmente con Room y se sincronizarán con Google Health Connect como `SleepSessionRecord`.

## Funcionalidades

### Implementado (Módulo 1)

- Pantalla principal con botones **Dormir** / **Despertar** (`TrackButtonsRow`).
- Máquina de estados en memoria con `StateFlow`:
  - Inicial: `Dormir` habilitado, `Despertar` deshabilitado, `sessionLine="Pulsa Dormir al apagar la luz"`.
  - Tras Dormir: `Dormir` deshabilitado, `Despertar` habilitado, `sleepSub="Desde HH:MM"`.
  - Tras Despertar: vuelve a inicial con `sessionLine="Guardado: Xh Ym esta noche"`.
- Tema M3 Expressive con `dynamicColor` (claro / oscuro).
- Accesibilidad: `contentDescription`, grupo accesible, foco visible, táctil mínimo.
- Prototipo web interactivo en `prototype.html` (réplica visual de la pantalla).

### Roadmap

- [ ] Room: entidad de sesión (inicio / fin / estado incompleto).
- [ ] Widget con Jetpack Glance + `GlanceAppWidgetReceiver`.
- [ ] Health Connect: escritura de `SleepSessionRecord`.
- [ ] WorkManager: reintento de sincronización en segundo plano.
- [ ] Navegación Stats / Ajustes + historial reciente.
- [ ] Permisos de Health Connect en el primer inicio.

## Stack

| Capa | Tecnología |
|---|---|
| UI | Jetpack Compose + Material3 Expressive (sin XML) |
| Arquitectura | MVVM (`UiState` + `ViewModel` + `StateFlow`) |
| Local (roadmap) | Room |
| Salud (roadmap) | Health Connect `SleepSessionRecord` |
| Fondo (roadmap) | Coroutines + WorkManager |
| Widget (roadmap) | Jetpack Glance |

Versiones fijadas en `gradle/libs.versions.toml`:

- AGP 8.5.2, Kotlin 2.0.20, `compileSdk` / `targetSdk` 34, `minSdk` 26, Java 17
- Compose BOM 2024.09.00, Material3 1.3.1, lifecycle 2.8.6, activity-compose 1.9.2

## Estructura

```text
app/src/main/java/com/sleepy3/app/
├── MainActivity.kt            # setContent + Sleepy3Theme
└── ui/
    ├── theme/Theme.kt         # dynamicColor claro/oscuro
    └── home/
        ├── SleepHomeUiState.kt      # isSleeping, sleepStartMillis, textos
        ├── SleepHomeViewModel.kt    # onSleepClick / onWakeClick
        ├── TrackButtonsRow.kt       # grid 2 columnas + Sleep/Wake buttons
        └── SleepHomeScreen.kt       # pantalla principal

app/src/test/.../SleepHomeViewModelTest.kt
prototype.html                  # maqueta web clicable (sin build)
SPEC.md                         # especificación técnica y de diseño
ToDo.md                         # alcance del Módulo 1
```

## Requisitos

- JDK 17
- Android Studio Ladybug o superior (AGP 8.5.2)
- SDK Android 34
- Un dispositivo / emulador Android 8.0+ (API 26)

No necesitas nada instalado para ver el prototipo web (ver abajo).

## Cómo verlo sin instalar nada

El prototipo es un solo archivo autocontenido:

1. Abre `prototype.html` con doble clic en tu PC, o
2. Envíatelo por WhatsApp / Telegram / Drive y ábrelo en el navegador del móvil.

Incluye reloj en vivo, escena día/noche, botones funcionales y mini-resumen de 3 días.

## Cómo ejecutar la app nativa

```bash
git clone https://github.com/Juankyyy/sleepy3.git
cd sleepy3

# Debug en dispositivo / emulador
./gradlew :app:assembleDebug
./gradlew :app:installDebug

# Tests unitarios (ViewModel)
./gradlew :app:testDebugUnitTest
```

En Windows usa `gradlew.bat` en lugar de `./gradlew`.

## Ramas

| Rama | Uso |
|---|---|
| `main` | Estable |
| `dev` | Integración de versiones usables |
| `debug` | Pruebas, experimentos y APKs |

Flujo: `debug` → `dev` → `main`.

## Diseño

Material Design 3 Expressive:

- Colores desde `MaterialTheme.colorScheme` con `dynamicColor` (primario vs. terciario para Dormir / Despertar).
- Esquinas grandes (`RoundedCornerShape`), tipografía contrastante.
- Sin animaciones agresivas (equivalente a `prefers-reduced-motion`).

Fuente visual: `prototype.html:160-175` (`.actions`, `.track-btn`).

## Tests

- `SleepHomeViewModelTest`: transiciones Dormir → Despertar, textos de `sleepSub` / `sessionLine` y cálculo de duración `Xh Ym`.

```bash
./gradlew :app:testDebugUnitTest
```

## Licencia

Sin licencia definida todavía. Todos los derechos reservados por defecto.
