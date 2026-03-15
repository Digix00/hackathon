package com.digix00.musicswapping.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digix00.musicswapping.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ProfileUiState(val nickname: String = "", val isLoading: Boolean = false, val error: String? = null)

@HiltViewModel
class ProfileViewModel @Inject constructor(private val userRepository: UserRepository) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    init {
        load()
    }

    private fun load() {
        viewModelScope.launch {
            runCatching { userRepository.getMe() }
                .onSuccess { user -> _uiState.update { it.copy(nickname = user.nickname) } }
        }
    }

    fun onNicknameChange(value: String) {
        _uiState.update { it.copy(nickname = value) }
    }

    fun save(onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            runCatching { userRepository.updateMe(nickname = uiState.value.nickname, avatarUrl = null) }
                .onSuccess {
                    _uiState.update { state -> state.copy(isLoading = false) }
                    onSuccess()
                }
                .onFailure { e -> _uiState.update { state -> state.copy(isLoading = false, error = e.message) } }
        }
    }
}
