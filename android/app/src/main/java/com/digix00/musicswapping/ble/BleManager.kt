package com.digix00.musicswapping.ble

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.UUID

/**
 * BLE トークンのアドバタイズ（Peripheral）とスキャン（Central）を管理する。
 *
 * Service UUID: このプロジェクト固有の UUID を使用する。
 * Token は毎日サーバー側でローテーションされる（追跡防止）。
 */
class BleManager(private val context: Context) {
    companion object {
        private const val TAG = "BleManager"

        /** プロジェクト固有の BLE Service UUID */
        val SERVICE_UUID: UUID = UUID.fromString("00001234-0000-1000-8000-00805f9b34fb")
    }

    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    }

    // ── Advertise ──────────────────────────────────────────────────

    private var advertiseCallback: AdvertiseCallback? = null

    @SuppressLint("MissingPermission")
    fun startAdvertising(bleToken: String, onError: (Int) -> Unit = {}) {
        if (!hasBluetoothPermissions()) {
            Log.w(TAG, "BLE permission not granted")
            return
        }
        val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser ?: return

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceData(ParcelUuid(SERVICE_UUID), bleToken.toByteArray(Charsets.UTF_8))
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartFailure(errorCode: Int) {
                Log.e(TAG, "Advertise failed: $errorCode")
                onError(errorCode)
            }
        }
        advertiser.startAdvertising(settings, data, advertiseCallback!!)
        Log.i(TAG, "Advertising started: $bleToken")
    }

    @SuppressLint("MissingPermission")
    fun stopAdvertising() {
        advertiseCallback?.let {
            bluetoothAdapter?.bluetoothLeAdvertiser?.stopAdvertising(it)
            advertiseCallback = null
        }
    }

    // ── Scan ───────────────────────────────────────────────────────

    private var scanCallback: ScanCallback? = null

    @SuppressLint("MissingPermission")
    fun startScanning(onTokenDetected: (token: String, rssi: Int) -> Unit) {
        if (!hasBluetoothPermissions()) {
            Log.w(TAG, "BLE permission not granted")
            return
        }
        val scanner: BluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner ?: return

        val filter = ScanFilter.Builder().build()

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val rawBytes = result.scanRecord
                    ?.getServiceData(ParcelUuid(SERVICE_UUID)) ?: return
                val token = rawBytes.toString(Charsets.UTF_8)
                onTokenDetected(token, result.rssi)
            }

            override fun onScanFailed(errorCode: Int) {
                Log.e(TAG, "Scan failed: $errorCode")
            }
        }
        scanner.startScan(listOf(filter), settings, scanCallback!!)
        Log.i(TAG, "Scanning started")
    }

    @SuppressLint("MissingPermission")
    fun stopScanning() {
        scanCallback?.let {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(it)
            scanCallback = null
        }
    }

    // ── Helpers ────────────────────────────────────────────────────

    fun isBluetoothEnabled(): Boolean = bluetoothAdapter?.isEnabled == true

    private fun hasBluetoothPermissions(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE
            )
        } else {
            listOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }
        return permissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }
}
