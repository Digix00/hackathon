package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestPostLocationRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseLocationResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface LocationsApi {
    /**
     * 現在位置送信・エンカウント判定
     * 現在位置をサーバーに送信し、近くにいるユーザーとのエンカウントを判定・作成する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param body 位置情報リクエスト
     * @return [HackathonInternalHandlerSchemaResponseLocationResponse]
     */
    @POST("api/v1/locations")
    suspend fun postLocation(@Body body: HackathonInternalHandlerSchemaRequestPostLocationRequest): Response<HackathonInternalHandlerSchemaResponseLocationResponse>

}
