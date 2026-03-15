package com.digix00.musicswapping.di

import android.content.Context
import androidx.room.Room
import com.digix00.musicswapping.data.local.AppDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase = Room.databaseBuilder(
        context,
        AppDatabase::class.java,
        "music_swapping.db"
    )
        .fallbackToDestructiveMigration()
        .build()

    @Provides
    fun provideEncounterDao(db: AppDatabase) = db.encounterDao()
}
