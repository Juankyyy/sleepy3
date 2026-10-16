package com.sleepy3.app.ui.home

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

// Criterio de done del ToDo del módulo 1, sin dependencias Android.
class SleepHomeViewModelTest {

    @Test
    fun initialState_sleepEnabled_wakeDisabled() {
        val vm = SleepHomeViewModel()
        val s = vm.uiState.value
        assertTrue(s.isSleepEnabled)
        assertFalse(s.isWakeEnabled)
        assertEquals("Pulsa Dormir al apagar la luz", s.sessionLine)
    }

    @Test
    fun sleepClick_disablesSleep_enablesWake() {
        val vm = SleepHomeViewModel()
        vm.onSleepClick(1_700_000_000_000L)
        val s = vm.uiState.value
        assertTrue(s.isSleeping)
        assertFalse(s.isSleepEnabled)
        assertTrue(s.isWakeEnabled)
        assertTrue(s.sleepSub.startsWith("Desde "))
        assertEquals("Pulsa al despertar", s.wakeSub)
    }

    @Test
    fun wakeClick_after90min_shows1h30m_andResets() {
        val vm = SleepHomeViewModel()
        val start = 1_700_000_000_000L
        vm.onSleepClick(start)
        vm.onWakeClick(start + 90L * 60_000L)
        val s = vm.uiState.value
        assertFalse(s.isSleeping)
        assertTrue(s.isSleepEnabled)
        assertEquals("Guardado: 1h 30m esta noche", s.sessionLine)
    }

    @Test
    fun doubleSleep_isIgnored() {
        val vm = SleepHomeViewModel()
        vm.onSleepClick(1000L)
        val first = vm.uiState.value.sleepStartMillis
        vm.onSleepClick(2000L)
        assertEquals(first, vm.uiState.value.sleepStartMillis)
    }
}
