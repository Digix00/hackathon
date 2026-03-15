package com.digix00.musicswapping.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

data class AuthUiState(val isLoading: Boolean = false, val isLoggedIn: Boolean = false, val error: String? = null)

@HiltViewModel
class AuthViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(
        AuthUiState(
            isLoggedIn = Firebase.auth.currentUser != null
        )
    )
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    /** Navigation で collectAsStateWithLifecycle() するための Flow */
    val isLoggedIn: StateFlow<Boolean> = _uiState
        .map { it.isLoggedIn }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), Firebase.auth.currentUser != null)

    /** local.properties または BuildConfig 経由で渡す想定 */
    val googleClientId: String = com.digix00.musicswapping.BuildConfig.GOOGLE_WEB_CLIENT_ID

    fun signInWithGoogle(idToken: String) {
        if (googleClientId.isBlank()) {
            _uiState.update {
                it.copy(
                    isLoading = false,
                    error = "Google ログイン設定が未完了です。local.properties の google.web_client_id を設定してください。"
                )
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            runCatching {
                val credential = GoogleAuthProvider.getCredential(idToken, null)
                Firebase.auth.signInWithCredential(credential).await()
            }.onSuccess {
                _uiState.update { state -> state.copy(isLoading = false, isLoggedIn = true) }
            }.onFailure { e ->
                _uiState.update { state -> state.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun onGoogleSignInFailed(message: String?) {
        _uiState.update {
            it.copy(
                isLoading = false,
                error = message ?: "Google ログインに失敗しました。設定を確認してください。"
            )
        }
    }
}
