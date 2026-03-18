package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateBlockRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseBlockResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface BlocksApi {
    /**
     * ブロック作成
     * 指定したユーザーをブロックする。自分自身や存在しないユーザーへのブロック、重複ブロックはエラーになる。
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param body ブロックリクエスト
     * @return [HackathonInternalHandlerSchemaResponseBlockResponse]
     */
    @POST("api/v1/users/me/blocks")
    suspend fun createBlock(@Body body: HackathonInternalHandlerSchemaRequestCreateBlockRequest): Response<HackathonInternalHandlerSchemaResponseBlockResponse>

    /**
     * ブロック解除
     * 指定したユーザーのブロックを解除する。ブロックが存在しない場合はエラーになる。
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param blockedUserId ブロック解除対象のユーザーID
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/blocks/{blocked_user_id}")
    suspend fun deleteBlock(@Path("blocked_user_id") blockedUserId: kotlin.String): Response<Unit>

}
