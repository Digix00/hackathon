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
    * enum for parameter provider
    */
    enum class ProviderDeleteMusicConnection(val value: kotlin.String) {
        @SerialName(value = "spotify") spotify("spotify"),
        @SerialName(value = "apple_music") apple_music("apple_music")
    }

    /**
     * 音楽連携を解除
     * 指定 provider の音楽連携を解除する
     * Responses:
     *  - 204: No Content
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param provider provider
     * @return [Unit]
     */
    @DELETE("api/v1/users/me/music-connections/{provider}")
    suspend fun deleteMusicConnection(@Path("provider") provider: kotlin.String): Response<Unit>


    /**
    * enum for parameter provider
    */
    enum class ProviderGetMusicAuthorizeURL(val value: kotlin.String) {
        @SerialName(value = "spotify") spotify("spotify"),
        @SerialName(value = "apple_music") apple_music("apple_music")
    }

    /**
     * 音楽サービス連携の認可 URL を取得
     * Spotify / Apple Music の OAuth 認可開始 URL と state を返す
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param provider provider
     * @return [HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse]
     */
    @GET("api/v1/music-connections/{provider}/authorize")
    suspend fun getMusicAuthorizeURL(@Path("provider") provider: kotlin.String): Response<HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse>


    /**
    * enum for parameter provider
    */
    enum class ProviderHandleMusicCallback(val value: kotlin.String) {
        @SerialName(value = "spotify") spotify("spotify"),
        @SerialName(value = "apple_music") apple_music("apple_music")
    }

    /**
     * 音楽サービス連携のコールバック
     * OAuth コールバックを処理し、アプリ deep link へリダイレクトする
     * Responses:
     *  - 302: Found
     *
     * @param provider provider
     * @param code authorization code
     * @param state signed state
     * @return [Unit]
     */
    @GET("api/v1/music-connections/{provider}/callback")
    suspend fun handleMusicCallback(@Path("provider") provider: kotlin.String, @Query("code") code: kotlin.String, @Query("state") state: kotlin.String): Response<Unit>

    /**
     * 自分の音楽連携一覧を取得
     * 連携済み Spotify / Apple Music アカウント一覧を返す
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseMusicConnectionsResponse]
     */
    @GET("api/v1/users/me/music-connections")
    suspend fun listMusicConnections(): Response<HackathonInternalHandlerSchemaResponseMusicConnectionsResponse>

}
