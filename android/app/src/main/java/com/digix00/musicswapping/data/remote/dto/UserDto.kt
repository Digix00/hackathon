package com.digix00.musicswapping.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

object UserDto {
    @Serializable
    data class Response(
        val id: String,
        @SerialName("firebase_uid") val firebaseUid: String,
        val nickname: String,
        @SerialName("avatar_url") val avatarUrl: String? = null
    )

    @Serializable
    data class CreateRequest(val nickname: String, @SerialName("avatar_url") val avatarUrl: String? = null)

    @Serializable
    data class UpdateRequest(val nickname: String? = null, @SerialName("avatar_url") val avatarUrl: String? = null)
}
