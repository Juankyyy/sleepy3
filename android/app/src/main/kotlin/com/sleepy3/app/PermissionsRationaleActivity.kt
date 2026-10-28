package com.sleepy3.app

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * Minimal in-app rationale for Health Connect permissions.
 *
 * Health Connect opens this screen when the user taps the permission rationale
 * or privacy link in its permission sheet. Keeping it native avoids starting
 * the Flutter engine just to show a static explanation.
 */
class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val density = resources.displayMetrics.density
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            val padding = (24 * density).toInt()
            setPadding(padding, padding, padding, padding)
        }

        content.addView(
            TextView(this).apply {
                text = getString(R.string.health_connect_rationale_title)
                textSize = 24f
            },
        )
        content.addView(
            TextView(this).apply {
                text = getString(R.string.health_connect_rationale_body)
                textSize = 16f
                val verticalPadding = (16 * density).toInt()
                setPadding(0, verticalPadding, 0, verticalPadding)
            },
        )
        content.addView(
            Button(this).apply {
                text = getString(R.string.health_connect_rationale_close)
                setOnClickListener { finish() }
            },
        )

        setContentView(
            ScrollView(this).apply {
                isFillViewport = true
                addView(content)
            },
        )
    }
}
