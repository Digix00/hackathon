package com.digix00.musicswapping.ui.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.digix00.musicswapping.data.preferences.AppPreferences
import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.domain.model.Track
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SearchUiState(val query: String = "", val results: List<Track> = emptyList(), val isLoading: Boolean = false)

@OptIn(FlowPreview::class)
@HiltViewModel
class SearchViewModel @Inject constructor(private val api: ApiService, private val prefs: AppPreferences) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private val queryFlow = MutableStateFlow("")

    init {
        queryFlow
            .debounce(SEARCH_DEBOUNCE_MS)
            .distinctUntilChanged()
            .onEach { q ->
                if (q.length >= 2) {
                    search(q)
                } else {
                    _uiState.update { it.copy(results = emptyList(), isLoading = false) }
                }
            }
            .launchIn(viewModelScope)
    }

    fun onQueryChange(q: String) {
        _uiState.update { it.copy(query = q) }
        queryFlow.value = q
    }

    private suspend fun search(q: String) {
        _uiState.update { it.copy(isLoading = true) }
        runCatching { api.searchTracks(q) }
            .onSuccess { dtos ->
                val tracks = dtos.map { dto ->
                    Track(
                        id = dto.id,
                        spotifyId = dto.spotifyId,
                        title = dto.title,
                        artist = dto.artist,
                        albumArtUrl = dto.albumArtUrl,
                        previewUrl = dto.previewUrl
                    )
                }
                _uiState.update { it.copy(results = tracks, isLoading = false) }
            }
            .onFailure { _uiState.update { state -> state.copy(isLoading = false) } }
    }

    fun selectTrack(track: Track) {
        viewModelScope.launch {
            prefs.setCurrentTrackId(track.id)
            // TODO: api.setMyTrack() を呼ぶ
        }
    }

    companion object {
        private const val SEARCH_DEBOUNCE_MS = 400L
    }
}
