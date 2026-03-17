package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseBleTokenResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseBleTokenUserResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface BleTokensApi {
    /**
     * BLE トークン発行
     * 現在ログインしているユーザーの新規 BLE トークンを発行する（24時間有効）
     * Responses:
     *  - 201: Created
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseBleTokenResponse]
     */
    @POST("api/v1/ble-tokens")
    suspend fun createBleToken(): Response<HackathonInternalHandlerSchemaResponseBleTokenResponse>

    /**
     * 有効な BLE トークン取得
     * 現在ログインしているユーザーの有効な最新の BLE トークンを取得する
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseBleTokenResponse]
     */
    @GET("api/v1/ble-tokens/current")
    suspend fun getCurrentBleToken(): Response<HackathonInternalHandlerSchemaResponseBleTokenResponse>

    /**
     * BLE トークンからユーザー情報取得
     * 指定した BLE トークンに紐づくユーザーの公開プロフィールを取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param token 対象の BLE トークン
     * @return [HackathonInternalHandlerSchemaResponseBleTokenUserResponse]
     */
    @GET("api/v1/ble-tokens/{token}/user")
    suspend fun getUserByBleToken(@Path("token") token: kotlin.String): Response<HackathonInternalHandlerSchemaResponseBleTokenUserResponse>

}
