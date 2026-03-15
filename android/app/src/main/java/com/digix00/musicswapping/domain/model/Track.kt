package com.digix00.musicswapping.domain.model

data class Track(
    val id: String,
    val spotifyId: String,
    val title: String,
    val artist: String,
    val albumArtUrl: String?,
    val previewUrl: String?
)
