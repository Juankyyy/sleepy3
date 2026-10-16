package com.sleepy3.app.ui.home

import androidx.lifecycle.ViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

// MVVM: el ViewModel posee la máquina de estados Dormir/Despertar.
// La interacción Glance Receiver <-> coroutines se documentará en el módulo del widget;
// aquí solo estado en memoria según ToDo del módulo 1.
class SleepHomeViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(SleepHomeUiState())
    val uiState: StateFlow<SleepHomeUiState> = _uiState.asStateFlow()

    fun onSleepClick(nowMillis: Long = System.currentTimeMillis()) {
        if (_uiState.value.isSleeping) return
        _uiState.update {
            it.copy(
                isSleeping = true,
                sleepStartMillis = nowMillis,
                sleepSub = "Desde ${formatShort(nowMillis)}",
                wakeSub = "Pulsa al despertar",
                sessionLine = "Durmiendo desde ${formatFull(nowMillis)}",
            )
        }
    }

    fun onWakeClick(nowMillis: Long = System.currentTimeMillis()) {
        val current = _uiState.value
        val start = current.sleepStartMillis
        if (!current.isSleeping || start == null) return
        val elapsed = (nowMillis - start).coerceAtLeast(0L)
        val hours = elapsed / 3_600_000L
        val minutes = (elapsed % 3_600_000L) / 60_000L
        _uiState.update {
            it.copy(
                isSleeping = false,
                sleepStartMillis = null,
                sleepSub = "Hora de dormir",
                wakeSub = "Hora de despertar",
                sessionLine = "Guardado: ${hours}h ${minutes}m esta noche",
            )
        }
    }

    private fun formatShort(millis: Long): String =
        SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(millis))

    private fun formatFull(millis: Long): String =
        SimpleDateFormat("h:mm:ss a", Locale.getDefault()).format(Date(millis))
}
