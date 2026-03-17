package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreatePushTokenRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseDeviceResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface PushTokensApi {
    /**
     * プッシュトークン登録（upsert）
     * device_id が既存なら更新して 200、新規なら 201 を返す
     * Responses:
     *  - 200: 既存デバイスを更新
     *  - 201: 新規デバイスを登録
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param body プッシュトークン登録リクエスト
     * @return [HackathonInternalHandlerSchemaResponseDeviceResponse]
     */
    @POST("api/v1/users/me/push-tokens")
    suspend fun createPushToken(@Body body: HackathonInternalHandlerSchemaRequestCreatePushTokenRequest): Response<HackathonInternalHandlerSchemaResponseDeviceResponse>

    /**
     * プッシュトークン削除
     * 指定デバイスのレコードを削除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id デバイス ID
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/push-tokens/{id}")
    suspend fun deletePushToken(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * プッシュトークン更新
     * 指定デバイスのトークン・有効フラグ・アプリバージョンを部分更新する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id デバイス ID
     * @param body プッシュトークン更新リクエスト
     * @return [HackathonInternalHandlerSchemaResponseDeviceResponse]
     */
    @PATCH("api/v1/users/me/push-tokens/{id}")
    suspend fun patchPushToken(@Path("id") id: kotlin.String, @Body body: HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest): Response<HackathonInternalHandlerSchemaResponseDeviceResponse>

}
