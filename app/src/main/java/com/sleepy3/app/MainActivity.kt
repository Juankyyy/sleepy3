package com.sleepy3.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.sleepy3.app.ui.home.SleepHomeScreen
import com.sleepy3.app.ui.theme.Sleepy3Theme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            Sleepy3Theme {
                SleepHomeScreen()
            }
        }
    }
}
