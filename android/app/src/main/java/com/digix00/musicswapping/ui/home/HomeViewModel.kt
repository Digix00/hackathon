package com.digix00.musicswapping.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digix00.musicswapping.data.repository.EncounterRepository
import com.digix00.musicswapping.domain.model.Encounter
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class HomeViewModel @Inject constructor(private val encounterRepository: EncounterRepository) : ViewModel() {

    val encounters: StateFlow<List<Encounter>> = encounterRepository
        .observeEncounters()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            runCatching { encounterRepository.syncFromRemote() }
        }
    }
}
