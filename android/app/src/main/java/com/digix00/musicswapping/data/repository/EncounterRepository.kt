package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.domain.model.Encounter
import kotlinx.coroutines.flow.Flow

interface EncounterRepository {
    fun observeEncounters(): Flow<List<Encounter>>
    suspend fun syncFromRemote()
    suspend fun like(encounterId: String)
}
