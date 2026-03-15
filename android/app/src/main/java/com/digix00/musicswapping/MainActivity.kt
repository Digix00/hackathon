package com.digix00.musicswapping

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.digix00.musicswapping.ui.navigation.AppNavigation
import com.digix00.musicswapping.ui.theme.MusicSwappingTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MusicSwappingTheme {
                AppNavigation()
            }
        }
    }
}
