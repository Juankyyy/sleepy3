package com.sleepy3.app.ui.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sleepy3.app.ui.theme.Sleepy3Theme

// Pantalla mínima del módulo 1: línea de sesión + fila de botones.
// El hero completo (reloj, escena día/noche) y el mini de 3 días llegan en el módulo 2/3.
@Composable
fun SleepHomeScreen(
    viewModel: SleepHomeViewModel = viewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    SleepHomeContent(
        state = state,
        onSleepClick = { viewModel.onSleepClick() },
        onWakeClick = { viewModel.onWakeClick() },
    )
}

@Composable
internal fun SleepHomeContent(
    state: SleepHomeUiState,
    onSleepClick: () -> Unit,
    onWakeClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Sleepy3",
            style = MaterialTheme.typography.headlineLarge,
        )
        Text(
            text = state.sessionLine,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, bottom = 12.dp),
        )
        TrackButtonsRow(
            state = state,
            onSleepClick = onSleepClick,
            onWakeClick = onWakeClick,
        )
    }
}

@Preview(name = "SleepHome — inicial")
@Composable
private fun SleepHomePreview() {
    Sleepy3Theme(dynamicColor = false) {
        SleepHomeContent(
            state = SleepHomeUiState(),
            onSleepClick = {},
            onWakeClick = {},
        )
    }
}
