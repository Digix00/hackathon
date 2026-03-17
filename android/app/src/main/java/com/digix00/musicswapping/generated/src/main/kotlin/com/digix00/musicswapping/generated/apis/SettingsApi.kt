package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestUpdateSettingsRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseSettingsResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface SettingsApi {
    /**
     * 自分の設定取得
     * 認証中のユーザーのアプリ設定を返す
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseSettingsResponse]
     */
    @GET("api/v1/users/me/settings")
    suspend fun getMySettings(): Response<HackathonInternalHandlerSchemaResponseSettingsResponse>

    /**
     * 自分の設定更新
     * 指定したフィールドだけを部分更新する（null フィールドは変更しない）
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param body 設定更新リクエスト
     * @return [HackathonInternalHandlerSchemaResponseSettingsResponse]
     */
    @PATCH("api/v1/users/me/settings")
    suspend fun patchMySettings(@Body body: HackathonInternalHandlerSchemaRequestUpdateSettingsRequest): Response<HackathonInternalHandlerSchemaResponseSettingsResponse>

}
