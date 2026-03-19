package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestAddUserTrackRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseUserTrackListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseUserTrackResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface UserTracksApi {
    /**
     * マイトラックに楽曲追加
     * 認証済みユーザーのマイトラックに楽曲を追加する。既に登録済みの場合は 200 を返す。
     * Responses:
     *  - 200: OK
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param body トラック追加リクエスト
     * @return [HackathonInternalHandlerSchemaResponseUserTrackResponse]
     */
    @POST("api/v1/users/me/tracks")
    suspend fun addUserTrack(@Body body: HackathonInternalHandlerSchemaRequestAddUserTrackRequest): Response<HackathonInternalHandlerSchemaResponseUserTrackResponse>

    /**
     * マイトラックから楽曲削除
     * 認証済みユーザーのマイトラックから楽曲を削除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id トラックID（例: spotify:track:123）
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/tracks/{id}")
    suspend fun deleteUserTrack(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * マイトラック一覧取得
     * 認証済みユーザーのマイトラック一覧をカーソルページネーションで取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param limit 取得件数（省略時 20、最大 50） (optional)
     * @param cursor ページネーションカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseUserTrackListResponse]
     */
    @GET("api/v1/users/me/tracks")
    suspend fun listUserTracks(@Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseUserTrackListResponse>

}
