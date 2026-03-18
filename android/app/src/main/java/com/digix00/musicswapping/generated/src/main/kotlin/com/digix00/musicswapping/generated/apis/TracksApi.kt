package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackSearchResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface TracksApi {
    /**
     * 楽曲詳細取得
     * 連携済み音楽アカウント経由でトラック詳細を取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id track id
     * @return [HackathonInternalHandlerSchemaResponseTrackResponse]
     */
    @GET("api/v1/tracks/{id}")
    suspend fun getTrack(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponseTrackResponse>

    /**
     * 楽曲検索
     * 連携済み Spotify アカウントを使ってトラック検索する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param q query
     * @param limit limit (max 50) (optional)
     * @param cursor opaque cursor (optional)
     * @return [HackathonInternalHandlerSchemaResponseTrackSearchResponse]
     */
    @GET("api/v1/tracks/search")
    suspend fun searchTracks(@Query("q") q: kotlin.String, @Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseTrackSearchResponse>

}
