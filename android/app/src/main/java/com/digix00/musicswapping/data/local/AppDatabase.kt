package com.digix00.musicswapping.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.digix00.musicswapping.data.local.dao.EncounterDao
import com.digix00.musicswapping.data.local.entity.EncounterEntity

@Database(
    entities = [EncounterEntity::class],
    version = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun encounterDao(): EncounterDao
}
