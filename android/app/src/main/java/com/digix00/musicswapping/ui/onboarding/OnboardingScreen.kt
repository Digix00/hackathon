package com.digix00.musicswapping.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.digix00.musicswapping.ui.profile.ProfileScreen

@Composable
fun OnboardingScreen(onComplete: () -> Unit, viewModel: OnboardingViewModel = hiltViewModel()) {
    var page by remember { mutableIntStateOf(0) }

    when (page) {
        0 -> PermissionPage(onNext = { page = 1 })
        1 -> ProfileSetupPage(
            onComplete = {
                viewModel.completeOnboarding()
                onComplete()
            }
        )
    }
}

/** 画面3: 権限（Bluetooth → 通知 → 位置情報 の順） */
@Composable
private fun PermissionPage(onNext: () -> Unit) {
    val btPermissions = if (Build.VERSION.SDK_INT >= 31) {
        arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT
        )
    } else {
        arrayOf(Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN)
    }

    val notificationPermissions = if (Build.VERSION.SDK_INT >= 33) {
        arrayOf(Manifest.permission.POST_NOTIFICATIONS)
    } else {
        arrayOf()
    }

    val locationPermissions = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

    val btLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { /* 結果は onboarding 完了後の実機確認で確認 */ }

    val notifLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) {}

    val locationLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) {}

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("アプリを使うために\n許可が必要です", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.height(32.dp))

        // 권限 요청 순서: Bluetooth → 통知 → 位置
        OutlinedButton(
            onClick = { btLauncher.launch(btPermissions) },
            modifier = Modifier.fillMaxWidth()
        ) { Text("Bluetooth を許可") }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(
            onClick = { notifLauncher.launch(notificationPermissions) },
            modifier = Modifier.fillMaxWidth()
        ) { Text("通知を許可") }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(
            onClick = { locationLauncher.launch(locationPermissions) },
            modifier = Modifier.fillMaxWidth()
        ) { Text("位置情報を許可") }
        Spacer(Modifier.height(32.dp))

        Button(onClick = onNext, modifier = Modifier.fillMaxWidth()) {
            Text("始める")
        }
    }
}

/** 画面2/4: プロフィール初期設定 */
@Composable
private fun ProfileSetupPage(onComplete: () -> Unit) {
    ProfileScreen(
        onBack = null,
        isOnboarding = true,
        onSaved = onComplete
    )
}
