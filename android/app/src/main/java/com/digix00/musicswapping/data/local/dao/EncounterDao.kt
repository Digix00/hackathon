package com.digix00.musicswapping.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.digix00.musicswapping.data.local.entity.EncounterEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface EncounterDao {

    @Query("SELECT * FROM encounters ORDER BY encountered_at_ms DESC")
    fun observeAll(): Flow<List<EncounterEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(encounters: List<EncounterEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(encounter: EncounterEntity)

    @Query("UPDATE encounters SET is_liked = :liked WHERE id = :id")
    suspend fun updateLike(id: String, liked: Boolean)

    @Query("SELECT * FROM encounters WHERE synced = 0")
    suspend fun getUnsynced(): List<EncounterEntity>

    @Query("UPDATE encounters SET synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<String>)
}
