package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseSharedTrackResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface SharedTrackApi {
    /**
     * シェア中の楽曲解除
     * 認証済みユーザーのシェア中の楽曲を解除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/shared-track")
    suspend fun deleteSharedTrack(): Response<Unit>

    /**
     * シェア中の楽曲取得
     * 認証済みユーザーが現在シェア中の楽曲を取得する。未設定の場合は shared_track: null を返す。
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseSharedTrackResponse]
     */
    @GET("api/v1/users/me/shared-track")
    suspend fun getSharedTrack(): Response<HackathonInternalHandlerSchemaResponseSharedTrackResponse>

    /**
     * シェア中の楽曲設定・更新
     * 認証済みユーザーのシェア中の楽曲を設定または更新する。初回設定時は 201、更新時は 200。
     * Responses:
     *  - 200: OK
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param body シェアトラック設定リクエスト
     * @return [HackathonInternalHandlerSchemaResponseSharedTrackResponse]
     */
    @PUT("api/v1/users/me/shared-track")
    suspend fun upsertSharedTrack(@Body body: HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest): Response<HackathonInternalHandlerSchemaResponseSharedTrackResponse>

}
