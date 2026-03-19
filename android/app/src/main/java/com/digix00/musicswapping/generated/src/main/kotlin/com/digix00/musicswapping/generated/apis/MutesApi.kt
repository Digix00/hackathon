package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateMuteRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseMuteResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface MutesApi {
    /**
     * ミュート作成
     * 指定したユーザーをミュートする。自分自身や存在しないユーザーへのミュート、重複ミュートはエラーになる。
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param body ミュートリクエスト
     * @return [HackathonInternalHandlerSchemaResponseMuteResponse]
     */
    @POST("api/v1/users/me/mutes")
    suspend fun createMute(@Body body: HackathonInternalHandlerSchemaRequestCreateMuteRequest): Response<HackathonInternalHandlerSchemaResponseMuteResponse>

    /**
     * ミュート解除
     * 指定したユーザーのミュートを解除する。ミュートが存在しない場合はエラーになる。
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param targetUserId ミュート解除対象のユーザーID
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/mutes/{target_user_id}")
    suspend fun deleteMute(@Path("target_user_id") targetUserId: kotlin.String): Response<Unit>

}
