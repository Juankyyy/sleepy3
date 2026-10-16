# Documento de Especificaciones Técnicas y de Diseño
**Nombre del Proyecto:** sleepy3
**Plataforma:** Android Nativo
**Lenguaje principal:** Kotlin

## 1. Resumen del Proyecto
"sleepy3" es una aplicación minimalista para registrar las horas de sueño. Su característica principal es la fricción cero: el usuario puede registrar la hora exacta en la que se duerme y se levanta mediante dos botones, accesibles tanto desde la aplicación principal como desde un widget en la pantalla de inicio. Los datos se guardan localmente y se sincronizan automáticamente con Google Health Connect.

## 2. Stack Tecnológico Obligatorio
El agente de IA debe generar código utilizando estrictamente estas tecnologías:
*   **UI Principal:** Jetpack Compose (`androidx.compose.material3`). **NO** usar XML para la UI.
*   **Diseño Visual:** Material Design 3 Expressive (temas dinámicos `dynamicColor`, paletas tonales, bordes muy redondeados, tipografía contrastante) para esto tienes la specs de material design 3 expressive en AGENTS.md
*   **UI del Widget:** Jetpack Glance (`androidx.glance:glance-appwidget`).
*   **Almacenamiento Local:** Room Database (`androidx.room`).
*   **Sincronización:** Health Connect API (`androidx.health.connect:connect-client`) usando `SleepSessionRecord`.
*   **Asincronismo y Tareas en Segundo Plano:** Kotlin Coroutines y WorkManager.
*   **Arquitectura:** MVVM (Model-View-ViewModel).

## 3. Características Principales (Core Features)
### A. Interfaz Principal (App)
*   Pantalla principal limpia con el historial reciente de sueño.
*   Dos botones principales ("Dormir" y "Despertar") de gran tamaño (Expressive style).
*   Gestión de permisos para Health Connect en el primer inicio.

### B. Widget de Pantalla de Inicio (Glance)
*   Widget minimalista que adopta los colores del sistema del usuario.
*   Dos botones: "Dormir" y "Despertar".
*   Al hacer clic, un `GlanceAppWidgetReceiver` captura el `System.currentTimeMillis()` en segundo plano sin abrir la app.

### C. Lógica de Base de Datos y Sincronización
*   **Dormir:** Crea un nuevo registro en Room con la hora de inicio y estado "incompleto".
*   **Despertar:** Actualiza el registro abierto con la hora de fin.
*   **Health Connect:** Inmediatamente después de cerrar el ciclo de sueño, los datos se empaquetan como `SleepSessionRecord` y se envían a la API de Health Connect de Google. Si falla, WorkManager reintenta en segundo plano.

## 4. Instrucciones Especiales para el Agente (Reglas del Skill)
*   **Actúa como un experto en Material Design 3 Expressive:** Siempre que generes código UI con Compose, prioriza el uso de `MaterialTheme.colorScheme`, esquinas redondeadas grandes (`RoundedCornerShape`), y animaciones fluidas para esto tienes la skill de Material Design 3 Exppressive.
*   **Código moderno:** Usa las prácticas más recientes de Kotlin y Jetpack Compose.
*   **Paso a paso:** No generes toda la app de golpe. Espera a que el usuario pida módulos específicos (ej. "Crea la entidad de Room", "Crea la UI del widget con Glance").
*   **Comentarios:** Documenta las partes complejas, especialmente la interacción entre el BroadcastReceiver del widget y los coroutines.