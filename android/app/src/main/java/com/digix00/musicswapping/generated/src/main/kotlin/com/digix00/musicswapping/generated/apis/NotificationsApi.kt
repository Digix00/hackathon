package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseNotificationListResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface NotificationsApi {
    /**
     * 通知一覧取得
     * 現在ログインしているユーザーの通知一覧を取得する
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param limit 取得件数（デフォルト: 20, 最大: 100） (optional)
     * @param offset オフセット（デフォルト: 0） (optional)
     * @return [HackathonInternalHandlerSchemaResponseNotificationListResponse]
     */
    @GET("api/v1/users/me/notifications")
    suspend fun listNotifications(@Query("limit") limit: kotlin.Int? = null, @Query("offset") offset: kotlin.Int? = null): Response<HackathonInternalHandlerSchemaResponseNotificationListResponse>

    /**
     * 通知を既読にする
     * 指定した通知を既読状態にする
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id 通知 ID
     * @return [Unit]
     */
    @PATCH("api/v1/users/me/notifications/{id}/read")
    suspend fun markNotificationAsRead(@Path("id") id: kotlin.String): Response<Unit>

}
