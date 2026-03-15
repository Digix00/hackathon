package com.digix00.musicswapping.ble

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.digix00.musicswapping.MainActivity
import com.digix00.musicswapping.R
import com.digix00.musicswapping.data.remote.ApiService
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Bluetooth LE のアドバタイズ + スキャンをバックグラウンドで常駐させる Foreground Service。
 * Android 12+ で BLUETOOTH_SCAN / BLUETOOTH_ADVERTISE 権限が付与されていることが前提。
 */
@AndroidEntryPoint
class BleForegroundService : Service() {

    companion object {
        private const val TAG = "BleForegroundService"
        private const val CHANNEL_ID = "ble_service"
        private const val NOTIFICATION_ID = 1001

        fun start(context: Context) {
            val intent = Intent(context, BleForegroundService::class.java)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BleForegroundService::class.java))
        }
    }

    @Inject lateinit var bleManager: BleManager

    @Inject lateinit var apiService: ApiService

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        initBle()
    }

    private fun initBle() {
        scope.launch {
            try {
                val tokenDto = apiService.getCurrentBleToken()
                bleManager.startAdvertising(tokenDto.token) { errorCode ->
                    Log.e(TAG, "Advertise error: $errorCode")
                }
                bleManager.startScanning { token, rssi ->
                    Log.d(TAG, "Detected token=$token rssi=$rssi")
                    // TODO: EncounterRepository 経由でサーバーに近接通知を送信
                }
            } catch (e: Exception) {
                Log.e(TAG, "BLE init failed", e)
            }
        }
    }

    override fun onDestroy() {
        bleManager.stopAdvertising()
        bleManager.stopScanning()
        scope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Notification ──────────────────────────────────────────────

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.ble_notification_channel_name),
            NotificationManager.IMPORTANCE_LOW
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.ble_notification_text))
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
