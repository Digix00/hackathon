package com.digix00.musicswapping.ui.home

import app.cash.turbine.test
import com.digix00.musicswapping.data.repository.EncounterRepository
import com.digix00.musicswapping.domain.model.Encounter
import com.digix00.musicswapping.domain.model.Track
import com.digix00.musicswapping.domain.model.User
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import java.time.Instant
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var repository: EncounterRepository
    private lateinit var viewModel: HomeViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        repository = mockk(relaxed = true)
        every { repository.observeEncounters() } returns flowOf(emptyList())
        viewModel = HomeViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `init triggers syncFromRemote`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        coVerify { repository.syncFromRemote() }
    }

    @Test
    fun `encounters StateFlow emits list from repository`() = runTest {
        val encounter = stubEncounter("e1")
        every { repository.observeEncounters() } returns flowOf(listOf(encounter))
        viewModel = HomeViewModel(repository)

        viewModel.encounters.test {
            var item = awaitItem()
            if (item.isEmpty()) {
                item = awaitItem()
            }
            assertEquals(1, item.size)
            assertEquals("e1", item[0].id)
            cancelAndIgnoreRemainingEvents()
        }
    }

    private fun stubEncounter(id: String) = Encounter(
        id = id,
        partnerUser = User(id = "u1", firebaseUid = "f1", nickname = "Alice", avatarUrl = null),
        sharedTrack = Track(id = "t1", spotifyId = "s1", title = "Song", artist = "Artist", albumArtUrl = null, previewUrl = null),
        encounteredAt = Instant.now(),
        isLiked = false
    )
}
