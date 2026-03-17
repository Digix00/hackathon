package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreatePlaylistRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponsePlaylistListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponsePlaylistResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface PlaylistsApi {
    /**
     * プレイリストをお気に入り登録
     * 指定したプレイリストをお気に入りに追加する（公開プレイリストのみ、または所有者）
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @return [Unit]
     */
    @POST("api/v1/playlists/{id}/favorites")
    suspend fun addPlaylistFavorite(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * プレイリストにトラック追加
     * プレイリストにトラックを追加する（所有者のみ）
     * Responses:
     *  - 204: No Content
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @param body トラック追加リクエスト
     * @return [Unit]
     */
    @POST("api/v1/playlists/{id}/tracks")
    suspend fun addPlaylistTrack(@Path("id") id: kotlin.String, @Body body: HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest): Response<Unit>

    /**
     * プレイリスト作成
     * 認証済みユーザーの新規プレイリストを作成する
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param body プレイリスト作成リクエスト
     * @return [HackathonInternalHandlerSchemaResponsePlaylistResponse]
     */
    @POST("api/v1/playlists")
    suspend fun createPlaylist(@Body body: HackathonInternalHandlerSchemaRequestCreatePlaylistRequest): Response<HackathonInternalHandlerSchemaResponsePlaylistResponse>

    /**
     * プレイリスト削除
     * プレイリストを削除する（所有者のみ）
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @return [Unit]
     */
    @DELETE("api/v1/playlists/{id}")
    suspend fun deletePlaylist(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * 自分のプレイリスト一覧取得
     * 認証済みユーザー自身のプレイリスト一覧を取得する
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponsePlaylistListResponse]
     */
    @GET("api/v1/playlists/me")
    suspend fun getMyPlaylists(): Response<HackathonInternalHandlerSchemaResponsePlaylistListResponse>

    /**
     * プレイリスト取得
     * 指定したプレイリストをトラック情報付きで取得する（公開プレイリストは誰でも取得可能、非公開は所有者のみ）
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @return [HackathonInternalHandlerSchemaResponsePlaylistResponse]
     */
    @GET("api/v1/playlists/{id}")
    suspend fun getPlaylist(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponsePlaylistResponse>

    /**
     * プレイリストのお気に入り解除
     * 指定したプレイリストをお気に入りから削除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @return [Unit]
     */
    @DELETE("api/v1/playlists/{id}/favorites")
    suspend fun removePlaylistFavorite(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * プレイリストからトラック削除
     * プレイリストからトラックを削除する（所有者のみ）
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @param trackId トラックID
     * @return [Unit]
     */
    @DELETE("api/v1/playlists/{id}/tracks/{trackId}")
    suspend fun removePlaylistTrack(@Path("id") id: kotlin.String, @Path("trackId") trackId: kotlin.String): Response<Unit>

    /**
     * プレイリスト更新
     * プレイリストの名前・説明・公開設定を更新する（所有者のみ）
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id プレイリストID
     * @param body プレイリスト更新リクエスト
     * @return [HackathonInternalHandlerSchemaResponsePlaylistResponse]
     */
    @PATCH("api/v1/playlists/{id}")
    suspend fun updatePlaylist(@Path("id") id: kotlin.String, @Body body: HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest): Response<HackathonInternalHandlerSchemaResponsePlaylistResponse>

}
