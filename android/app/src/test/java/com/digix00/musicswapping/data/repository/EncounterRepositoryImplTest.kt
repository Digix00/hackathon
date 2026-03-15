package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.data.local.dao.EncounterDao
import com.digix00.musicswapping.data.local.entity.EncounterEntity
import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.data.remote.dto.EncounterDto
import com.digix00.musicswapping.data.remote.dto.TrackDto
import com.digix00.musicswapping.data.remote.dto.UserDto
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class EncounterRepositoryImplTest {

    private lateinit var api: ApiService
    private lateinit var dao: EncounterDao
    private lateinit var repository: EncounterRepositoryImpl

    @Before
    fun setUp() {
        api = mockk()
        dao = mockk(relaxed = true)
        repository = EncounterRepositoryImpl(api, dao)
    }

    @Test
    fun `syncFromRemote inserts all remote encounters into dao`() = runTest {
        // Given
        val dto = EncounterDto(
            id = "e1",
            partnerUser = UserDto.Response(id = "u1", firebaseUid = "f1", nickname = "Alice"),
            sharedTrack = TrackDto(id = "t1", spotifyId = "s1", title = "Song", artist = "Artist"),
            encounteredAt = "2026-03-15T10:00:00Z",
            isLiked = false
        )
        coEvery { api.getEncounters() } returns listOf(dto)

        // When
        repository.syncFromRemote()

        // Then
        coVerify { dao.insertAll(any()) }
    }

    @Test
    fun `like calls api and updates dao`() = runTest {
        // Given
        coEvery { api.likeEncounter(any()) } returns Unit

        // When
        repository.like("e1")

        // Then
        coVerify { api.likeEncounter("e1") }
        coVerify { dao.updateLike("e1", true) }
    }

    @Test
    fun `observeEncounters maps entity to domain correctly`() = runTest {
        // Given
        val entity = EncounterEntity(
            id = "e1",
            partnerUserId = "u1",
            partnerNickname = "Alice",
            trackId = "t1",
            trackTitle = "Song",
            trackArtist = "Artist",
            albumArtUrl = null,
            encounteredAtMs = 1_000_000L,
            isLiked = false,
            synced = true
        )
        coEvery { dao.observeAll() } returns flowOf(listOf(entity))

        // When
        repository.observeEncounters().collect { list ->
            // Then
            assertEquals(1, list.size)
            assertEquals("e1", list[0].id)
            assertEquals("Alice", list[0].partnerUser.nickname)
            assertEquals("Song", list[0].sharedTrack.title)
        }
    }
}
