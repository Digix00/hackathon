package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.data.local.dao.EncounterDao
import com.digix00.musicswapping.data.local.entity.EncounterEntity
import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.domain.model.Encounter
import com.digix00.musicswapping.domain.model.Track
import com.digix00.musicswapping.domain.model.User
import java.time.Instant
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class EncounterRepositoryImpl @Inject constructor(private val api: ApiService, private val dao: EncounterDao) : EncounterRepository {

    override fun observeEncounters(): Flow<List<Encounter>> = dao.observeAll().map { list -> list.map { it.toDomain() } }

    override suspend fun syncFromRemote() {
        val remote = api.getEncounters()
        val entities = remote.map { dto ->
            EncounterEntity(
                id = dto.id,
                partnerUserId = dto.partnerUser.id,
                partnerNickname = dto.partnerUser.nickname,
                trackTitle = dto.sharedTrack.title,
                trackArtist = dto.sharedTrack.artist,
                albumArtUrl = dto.sharedTrack.albumArtUrl,
                encounteredAtMs = Instant.parse(dto.encounteredAt).toEpochMilli(),
                isLiked = dto.isLiked,
                synced = true
            )
        }
        dao.insertAll(entities)
    }

    override suspend fun like(encounterId: String) {
        api.likeEncounter(encounterId)
        dao.updateLike(encounterId, true)
    }

    private fun EncounterEntity.toDomain() = Encounter(
        id = id,
        partnerUser = User(
            id = partnerUserId,
            firebaseUid = "",
            nickname = partnerNickname,
            avatarUrl = null
        ),
        sharedTrack = Track(
            id = id,
            spotifyId = "",
            title = trackTitle,
            artist = trackArtist,
            albumArtUrl = albumArtUrl,
            previewUrl = null
        ),
        encounteredAt = Instant.ofEpochMilli(encounteredAtMs),
        isLiked = isLiked
    )
}
