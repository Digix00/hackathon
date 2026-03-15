package com.digix00.musicswapping.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class EncounterDto(
    val id: String,
    @SerialName("partner_user") val partnerUser: UserDto.Response,
    @SerialName("shared_track") val sharedTrack: TrackDto,
    @SerialName("encountered_at") val encounteredAt: String,
    @SerialName("is_liked") val isLiked: Boolean = false
)
