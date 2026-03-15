package com.digix00.musicswapping.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "app_prefs")

@Singleton
class AppPreferences @Inject constructor(@ApplicationContext private val context: Context) {
    private val onboardingCompletedKey = booleanPreferencesKey("onboarding_completed")
    private val currentTrackIdKey = stringPreferencesKey("current_track_id")
    private val fcmTokenKey = stringPreferencesKey("fcm_token")

    val isOnboardingCompleted: Flow<Boolean> =
        context.dataStore.data.map { it[onboardingCompletedKey] ?: false }

    suspend fun setOnboardingCompleted() {
        context.dataStore.edit { it[onboardingCompletedKey] = true }
    }

    val currentTrackId: Flow<String?> =
        context.dataStore.data.map { it[currentTrackIdKey] }

    suspend fun setCurrentTrackId(id: String) {
        context.dataStore.edit { it[currentTrackIdKey] = id }
    }

    suspend fun saveFcmToken(token: String) {
        context.dataStore.edit { it[fcmTokenKey] = token }
    }
}
