package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.domain.model.User

interface UserRepository {
    suspend fun createUser(nickname: String, avatarUrl: String?): User
    suspend fun getMe(): User
    suspend fun updateMe(nickname: String?, avatarUrl: String?): User
}
