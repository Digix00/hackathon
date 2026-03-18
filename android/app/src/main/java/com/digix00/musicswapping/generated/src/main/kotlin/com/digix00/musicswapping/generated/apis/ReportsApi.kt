package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateReportRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseReportResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface ReportsApi {
    /**
     * 通報作成
     * ユーザーまたはコメントを通報する。同じ対象への重複通報はエラーになる。
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param body 通報リクエスト
     * @return [HackathonInternalHandlerSchemaResponseReportResponse]
     */
    @POST("api/v1/reports")
    suspend fun createReport(@Body body: HackathonInternalHandlerSchemaRequestCreateReportRequest): Response<HackathonInternalHandlerSchemaResponseReportResponse>

}
