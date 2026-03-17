package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateEncounterRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseEncounterDetailResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseEncounterListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseEncounterResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface EncountersApi {
    /**
     * すれ違い登録
     * BLE 検出トークンからすれ違いを登録する（同一ペア・短時間内は冪等）
     * Responses:
     *  - 200: OK
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param body すれ違い登録リクエスト
     * @return [HackathonInternalHandlerSchemaResponseEncounterResponse]
     */
    @POST("api/v1/encounters")
    suspend fun createEncounter(@Body body: HackathonInternalHandlerSchemaRequestCreateEncounterRequest): Response<HackathonInternalHandlerSchemaResponseEncounterResponse>

    /**
     * すれ違い詳細取得
     * 指定した ID のすれ違い詳細を取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id 対象すれ違い ID
     * @return [HackathonInternalHandlerSchemaResponseEncounterDetailResponse]
     */
    @GET("api/v1/encounters/{id}")
    suspend fun getEncounterByID(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponseEncounterDetailResponse>

    /**
     * すれ違い履歴一覧取得
     * 認証ユーザーのすれ違い履歴を取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param limit 取得件数（省略時 20, 最大 50） (optional)
     * @param cursor 次ページ取得用カーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseEncounterListResponse]
     */
    @GET("api/v1/encounters")
    suspend fun listEncounters(@Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseEncounterListResponse>

}
