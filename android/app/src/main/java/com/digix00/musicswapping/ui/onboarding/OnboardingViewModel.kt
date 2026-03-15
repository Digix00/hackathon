package com.digix00.musicswapping.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digix00.musicswapping.data.preferences.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.launch

@HiltViewModel
class OnboardingViewModel @Inject constructor(private val prefs: AppPreferences) : ViewModel() {
    fun completeOnboarding() {
        viewModelScope.launch { prefs.setOnboardingCompleted() }
    }
}
