package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseMusicConnectionsResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface MusicConnectionsApi {
    /**
     * 音楽サービス連携解除
     * 指定プロバイダーの連携を解除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *
     * @param provider spotify | apple_music
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/music-connections/{provider}")
    suspend fun deleteMyMusicConnection(@Path("provider") provider: kotlin.String): Response<Unit>

    /**
     * 音楽サービス OAuth 認可 URL 取得
     * 指定プロバイダーの OAuth 認可フローを開始し authorize_url を返す
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *
     * @param provider spotify | apple_music
     * @return [HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse]
     */
    @GET("api/v1/music-connections/{provider}/authorize")
    suspend fun getMusicAuthorizeURL(@Path("provider") provider: kotlin.String): Response<HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse>

    /**
     * 音楽サービス連携一覧取得
     * 自分の音楽サービス連携一覧を返す
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *
     * @return [HackathonInternalHandlerSchemaResponseMusicConnectionsResponse]
     */
    @GET("api/v1/users/me/music-connections")
    suspend fun getMyMusicConnections(): Response<HackathonInternalHandlerSchemaResponseMusicConnectionsResponse>

    /**
     * 音楽サービス OAuth コールバック
     * OAuth コールバックを処理し、認可コードをトークンに交換してアプリへリダイレクト
     * Responses:
     *  - 302: Found
     *
     * @param provider spotify | apple_music
     * @param code 認可コード
     * @param state CSRF state
     * @return [Unit]
     */
    @GET("api/v1/music-connections/{provider}/callback")
    suspend fun handleMusicCallback(@Path("provider") provider: kotlin.String, @Query("code") code: kotlin.String, @Query("state") state: kotlin.String): Response<Unit>

}
