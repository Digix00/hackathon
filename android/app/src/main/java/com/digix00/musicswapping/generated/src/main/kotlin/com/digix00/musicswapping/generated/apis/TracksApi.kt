package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackDetailResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackSearchResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface TracksApi {
    /**
     * トラック詳細取得
     * 指定トラックの詳細を返す（ID: &lt;provider&gt;:track:&lt;external_id&gt;）
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *
     * @param id トラック ID（例: spotify:track:123）
     * @return [HackathonInternalHandlerSchemaResponseTrackDetailResponse]
     */
    @GET("api/v1/tracks/{id}")
    suspend fun getTrack(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponseTrackDetailResponse>

    /**
     * トラック検索
     * Spotify Web API にプロキシするトラック検索
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *
     * @param q 検索キーワード
     * @param limit 件数（省略時20、最大50） (optional)
     * @param cursor 次ページカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseTrackSearchResponse]
     */
    @GET("api/v1/tracks/search")
    suspend fun searchTracks(@Query("q") q: kotlin.String, @Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseTrackSearchResponse>

}
