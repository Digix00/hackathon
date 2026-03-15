package com.digix00.musicswapping.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TrackDto(
    val id: String,
    @SerialName("spotify_id") val spotifyId: String,
    val title: String,
    val artist: String,
    @SerialName("album_art_url") val albumArtUrl: String? = null,
    @SerialName("preview_url") val previewUrl: String? = null
) {
    @Serializable
    data class SetRequest(
        @SerialName("spotify_id") val spotifyId: String,
        val title: String,
        val artist: String,
        @SerialName("album_art_url") val albumArtUrl: String? = null
    )
}
