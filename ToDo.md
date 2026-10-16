# ToDo — Módulo 1: actions (Dormir / Despertar)

Fuente UI: `prototype.html:160-175` (.actions, .track-btn, btnSleep/btnWake).
Fuente proyecto: `SPEC.md §3A` + `§3C` (solo estado en memoria en este módulo).

## Objetivo
Replicar los dos botones principales de la pantalla inicial con su máquina de estados,
en Jetpack Compose + M3 Expressive, arquitectura MVVM, sin persistencia todavía.

## Alcance / No alcance
- Sí: UI + `UiState` + `ViewModel` en memoria, previews claro/oscuro.
- No: Room, Health Connect, Glance/Widget, WorkManager, navegación Stats/Ajustes.

## Tareas
- [x] 1. Revisar skill M3 Expressive (`SKILL.md` + `references/components/buttons.md`, `tokens.md`, `component-tokens.md`) para variante de botón, forma, color y tipo. No usar valores de memoria.
- [x] 2. Definir `UiState`: `isSleeping: Boolean`, `sleepStartMillis: Long?`, textos de `sleepSub`, `wakeSub`, `sessionLine`.
- [x] 3. Crear `ViewModel` con `StateFlow`: `onSleepClick(nowMillis)`, `onWakeClick(nowMillis)`. Lógica espejo del JS del prototipo: Dormir deshabilita Dormir / habilita Despertar y viceversa.
- [x] 4. Crear `TrackButtonsRow`: grid 2 columnas, mismo `gap` visual que `.actions`.
- [x] 5. Crear `SleepButton` / `WakeButton`: icono + label + sub, estilo Expressive grande, colores `colorScheme` con `dynamicColor` (primario vs terciario).
- [x] 6. Accesibilidad: `contentDescription`, grupo accesible, foco visible, táctil mínimo, sin animación agresiva (equivalente a `prefers-reduced-motion`).
- [x] 7. Previews `@Preview`: (a) inicial — Dormir habilitado, (b) durmiendo — Despertar habilitado, (c) claro/oscuro dinámico.
- [ ] 8. Verificación: compila, cambio de estado y textos correctos al pulsar, sin regresiones.

## Criterio de done
- Estado inicial: `sessionLine="Pulsa Dormir al apagar la luz"`, Wake disabled.
- Tras Dormir: Sleep disabled, Wake enabled, `sleepSub="Desde HH:MM"`, `sessionLine="Durmiendo desde..."`.
- Tras Despertar: vuelve a inicial + `sessionLine="Guardado: Xh Ym esta noche"`.
