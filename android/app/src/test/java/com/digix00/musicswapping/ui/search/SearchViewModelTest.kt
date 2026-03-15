package com.digix00.musicswapping.ui.search

import com.digix00.musicswapping.data.preferences.AppPreferences
import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.data.remote.dto.TrackDto
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SearchViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var api: ApiService
    private lateinit var prefs: AppPreferences
    private lateinit var viewModel: SearchViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        api = mockk()
        prefs = mockk(relaxed = true)
        viewModel = SearchViewModel(api, prefs)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is empty`() {
        assertTrue(viewModel.uiState.value.results.isEmpty())
        assertEquals("", viewModel.uiState.value.query)
    }

    @Test
    fun `onQueryChange updates query in state`() = runTest {
        viewModel.onQueryChange("Bohemian")
        assertEquals("Bohemian", viewModel.uiState.value.query)
    }

    @Test
    fun `search debounce triggers api call after 400ms`() = runTest {
        // Given
        val trackDto = TrackDto(
            id = "t1",
            spotifyId = "s1",
            title = "Bohemian Rhapsody",
            artist = "Queen"
        )
        coEvery { api.searchTracks("Bohemian") } returns listOf(trackDto)

        // When
        viewModel.onQueryChange("Bohemian")
        testDispatcher.scheduler.advanceTimeBy(500)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        assertEquals(1, viewModel.uiState.value.results.size)
        assertEquals("Bohemian Rhapsody", viewModel.uiState.value.results[0].title)
    }
}
