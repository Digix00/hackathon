package com.digix00.musicswapping.data.remote

import com.digix00.musicswapping.data.remote.dto.EncounterDto
import com.digix00.musicswapping.data.remote.dto.TrackDto
import com.digix00.musicswapping.data.remote.dto.UserDto
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface ApiService {

    // ── User ────────────────────────────────────────────────────────
    @POST("users")
    suspend fun createUser(@Body body: UserDto.CreateRequest): UserDto.Response

    @GET("users/me")
    suspend fun getMe(): UserDto.Response

    @PATCH("users/me")
    suspend fun updateMe(@Body body: UserDto.UpdateRequest): UserDto.Response

    // ── Track ───────────────────────────────────────────────────────
    @GET("tracks/search")
    suspend fun searchTracks(@Query("q") query: String): List<TrackDto>

    @POST("users/me/tracks")
    suspend fun setMyTrack(@Body body: TrackDto.SetRequest): TrackDto

    // ── Encounter ───────────────────────────────────────────────────
    @GET("encounters")
    suspend fun getEncounters(): List<EncounterDto>

    @POST("encounters/{id}/favorites")
    suspend fun likeEncounter(@Path("id") id: String): Unit

    // ── BLE Token ───────────────────────────────────────────────────
    @POST("ble-tokens")
    suspend fun issueBleToken(): BleTokenDto

    @GET("ble-tokens/current")
    suspend fun getCurrentBleToken(): BleTokenDto
}

/** BLE トークン DTO（参照形式が小さいためここに定義） */
@kotlinx.serialization.Serializable
data class BleTokenDto(val token: String, val expiresAt: String)
