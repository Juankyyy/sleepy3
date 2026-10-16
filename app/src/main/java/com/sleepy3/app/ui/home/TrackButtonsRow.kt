package com.sleepy3.app.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.sleepy3.app.ui.theme.Sleepy3Theme

// Fila Dormir / Despertar — réplica de prototype.html .actions + .track-btn.
//
// From M3 (verificadas en el skill):
// - Gap 12dp: per Compose M3 tokens, `ButtonGroupSmall / BetweenSpace = 12.0.dp`
//   (references/component-tokens.md, sección Buttons).
// - Radio 32dp: `CornerExtraLargeIncreased = 32dp` en la escala de 10 pasos
//   (references/tokens.md, "Corner radius scale").
// - Icono 32dp: `ButtonLarge / IconSize = 32.0.dp`
//   (references/component-tokens.md, sección Buttons).
// - Colores: Dormir = primaryContainer/onPrimaryContainer (énfasis alto, estilo filled);
//   Despertar = tertiaryContainer/onTertiaryContainer. references/components/buttons.md
//   permite otros roles si contenedor y texto mantienen contraste 3:1.
// - Tipografía: label = `titleLarge` (22sp/28sp/0sp/Regular), sub = `bodySmall`
//   (12sp/16sp/0.4sp/Regular) — valores de references/tokens.md, "Type scale".
// - Accesibilidad: objetivo mínimo 48x48dp (references/components/buttons.md §10);
//   estos tiles lo superan con creces.
//
// My design decisions (no en M3):
// - Altura mínima 168dp: supera `ButtonXLarge / ContainerHeight = 136dp`; es un hero tile,
//   no un M3 Button estándar.
// - Círculo de icono 60dp y layout icono-arriba-de-etiqueta: M3 Buttons dice
//   "Don't vertically align an icon and text in the center of a button (icon above label)"
//   (references/components/buttons.md §9). Se mantiene el apilado del prototipo como
//   decisión de diseño consciente para el momento hero Dormir/Despertar.
// - Sin morph de forma al presionar en v1 (M3 define radios pressed por tamaño;
//   aquí se usa el radio 32dp en todos los estados).
@Composable
fun TrackButtonsRow(
    state: SleepHomeUiState,
    onSleepClick: () -> Unit,
    onWakeClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        TrackTile(
            label = "Dormir",
            sub = state.sleepSub,
            enabled = state.isSleepEnabled,
            containerColor = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            icon = {
                Icon(
                    imageVector = Icons.Filled.Bedtime,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                )
            },
            onClick = onSleepClick,
            contentDescription = "Dormir",
            modifier = Modifier.weight(1f),
        )
        TrackTile(
            label = "Despertar",
            sub = state.wakeSub,
            enabled = state.isWakeEnabled,
            containerColor = MaterialTheme.colorScheme.tertiaryContainer,
            contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
            icon = {
                Icon(
                    imageVector = Icons.Filled.WbSunny,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                )
            },
            onClick = onWakeClick,
            contentDescription = "Despertar",
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun TrackTile(
    label: String,
    sub: String,
    enabled: Boolean,
    containerColor: androidx.compose.ui.graphics.Color,
    contentColor: androidx.compose.ui.graphics.Color,
    icon: @Composable () -> Unit,
    onClick: () -> Unit,
    contentDescription: String,
    modifier: Modifier = Modifier,
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(32.dp),
        color = containerColor,
        contentColor = contentColor,
        modifier = modifier
            .heightIn(min = 168.dp)
            .semantics { role = Role.Button },
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Surface(
                shape = CircleShape,
                color = contentColor.copy(alpha = 0.14f),
                contentColor = contentColor,
                modifier = Modifier.size(60.dp),
            ) {
                androidx.compose.foundation.layout.Box(
                    contentAlignment = Alignment.Center,
                ) {
                    icon()
                }
            }
            Text(
                text = label,
                style = MaterialTheme.typography.titleLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp),
            )
            Text(
                text = sub,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Preview(name = "Inicial — Dormir habilitado")
@Composable
private fun TrackButtonsPreviewInitial() {
    Sleepy3Theme(dynamicColor = false) {
        TrackButtonsRow(
            state = SleepHomeUiState(),
            onSleepClick = {},
            onWakeClick = {},
        )
    }
}

@Preview(name = "Durmiendo — Despertar habilitado")
@Composable
private fun TrackButtonsPreviewSleeping() {
    Sleepy3Theme(dynamicColor = false) {
        TrackButtonsRow(
            state = SleepHomeUiState(
                isSleeping = true,
                sleepStartMillis = 0L,
                sleepSub = "Desde 11:40 PM",
                wakeSub = "Pulsa al despertar",
            ),
            onSleepClick = {},
            onWakeClick = {},
        )
    }
}
