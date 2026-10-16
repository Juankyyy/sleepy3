package com.sleepy3.app.ui.home

// Estado UI del módulo 1 (actions). Solo memoria; sin Room/Health/Glance.
// Espejo de la lógica JS de prototype.html: btnSleep/btnWake + sleepSub/wakeSub/sessionLine.
data class SleepHomeUiState(
    val isSleeping: Boolean = false,
    val sleepStartMillis: Long? = null,
    val sleepSub: String = "Hora de dormir",
    val wakeSub: String = "Hora de despertar",
    val sessionLine: String = "Pulsa Dormir al apagar la luz",
) {
    val isSleepEnabled: Boolean get() = !isSleeping
    val isWakeEnabled: Boolean get() = isSleeping
}
