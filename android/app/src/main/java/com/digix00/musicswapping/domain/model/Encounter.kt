package com.digix00.musicswapping.domain.model

import java.time.Instant

data class Encounter(val id: String, val partnerUser: User, val sharedTrack: Track, val encounteredAt: Instant, val isLiked: Boolean)
