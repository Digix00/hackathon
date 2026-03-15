package com.digix00.musicswapping.data.repository

import com.digix00.musicswapping.data.remote.ApiService
import com.digix00.musicswapping.data.remote.dto.UserDto
import com.digix00.musicswapping.domain.model.User
import javax.inject.Inject

class UserRepositoryImpl @Inject constructor(private val api: ApiService) : UserRepository {

    override suspend fun createUser(nickname: String, avatarUrl: String?): User =
        api.createUser(UserDto.CreateRequest(nickname, avatarUrl)).toDomain()

    override suspend fun getMe(): User = api.getMe().toDomain()

    override suspend fun updateMe(nickname: String?, avatarUrl: String?): User =
        api.updateMe(UserDto.UpdateRequest(nickname, avatarUrl)).toDomain()

    private fun UserDto.Response.toDomain() = User(
        id = id,
        firebaseUid = firebaseUid,
        nickname = nickname,
        avatarUrl = avatarUrl
    )
}
