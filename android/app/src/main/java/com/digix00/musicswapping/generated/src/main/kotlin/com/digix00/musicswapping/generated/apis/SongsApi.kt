package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseLikeSongResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseListUserSongsResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface SongsApi {
    /**
     * 楽曲にいいね
     * 指定した楽曲にいいねする。すでにいいね済みの場合は既存状態を返す。
     * Responses:
     *  - 200: OK
     *  - 201: Created
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param id 楽曲ID
     * @return [HackathonInternalHandlerSchemaResponseLikeSongResponse]
     */
    @POST("api/v1/songs/{id}/likes")
    suspend fun likeSong(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponseLikeSongResponse>

    /**
     * 自分が参加した楽曲一覧
     * 自分がLyricChainに参加して生成された楽曲の一覧を返す。
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param cursor ページネーションカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseListUserSongsResponse]
     */
    @GET("api/v1/users/me/songs")
    suspend fun listMySongs(@Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseListUserSongsResponse>

    /**
     * 楽曲のいいねを取り消す
     * 指定した楽曲のいいねを取り消す。いいねが存在しない場合はエラー。
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id 楽曲ID
     * @return [Unit]
     */
    @DELETE("api/v1/songs/{id}/likes")
    suspend fun unlikeSong(@Path("id") id: kotlin.String): Response<Unit>

}
