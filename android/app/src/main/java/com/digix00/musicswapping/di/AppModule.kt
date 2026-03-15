package com.digix00.musicswapping.di

import com.digix00.musicswapping.data.repository.EncounterRepository
import com.digix00.musicswapping.data.repository.EncounterRepositoryImpl
import com.digix00.musicswapping.data.repository.UserRepository
import com.digix00.musicswapping.data.repository.UserRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AppModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository

    @Binds
    @Singleton
    abstract fun bindEncounterRepository(impl: EncounterRepositoryImpl): EncounterRepository
}
