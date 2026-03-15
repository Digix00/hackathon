package com.digix00.musicswapping

import android.app.Application
import com.digix00.musicswapping.data.remote.FirebaseAuthTokenCache
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class MusicSwappingApp : Application() {

    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        FirebaseAuthTokenCache.start()
        configureFirebaseEmulator()
    }

    private fun configureFirebaseEmulator() {
        if (BuildConfig.FIREBASE_USE_EMULATOR == "true") {
            Firebase.auth.useEmulator("10.0.2.2", FIREBASE_AUTH_EMULATOR_PORT)
        }
    }

    companion object {
        private const val FIREBASE_AUTH_EMULATOR_PORT = 9099
    }
}
