package com.digix00.musicswapping.ui.encounter

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digix00.musicswapping.data.repository.EncounterRepository
import com.digix00.musicswapping.domain.model.Encounter
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class EncounterDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val encounterRepository: EncounterRepository
) : ViewModel() {

    private val encounterId: String = checkNotNull(savedStateHandle["encounterId"])

    val encounter: StateFlow<Encounter?> = encounterRepository
        .observeEncounters()
        .map { list -> list.find { it.id == encounterId } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    fun toggleLike(id: String) {
        viewModelScope.launch {
            runCatching { encounterRepository.like(id) }
        }
    }
}
