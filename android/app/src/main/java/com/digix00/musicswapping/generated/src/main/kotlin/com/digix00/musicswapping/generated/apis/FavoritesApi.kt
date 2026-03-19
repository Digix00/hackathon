package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseTrackFavoriteResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface FavoritesApi {
    /**
     * トラックをお気に入り登録
     * 指定したトラックをお気に入りに追加する。既にお気に入り済みの場合はべき等に処理し 200 を返す。
     * Responses:
     *  - 200: OK
     *  - 201: Created
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id トラックID（例: spotify:track:123）
     * @return [HackathonInternalHandlerSchemaResponseTrackFavoriteResponse]
     */
    @POST("api/v1/tracks/{id}/favorites")
    suspend fun addTrackFavorite(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponseTrackFavoriteResponse>

    /**
     * お気に入りプレイリスト一覧取得
     * 認証済みユーザーのお気に入りプレイリスト一覧をカーソルページネーションで取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param limit 取得件数（省略時 20、最大 50） (optional)
     * @param cursor ページネーションカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse]
     */
    @GET("api/v1/users/me/playlist-favorites")
    suspend fun listPlaylistFavorites(@Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse>

    /**
     * お気に入りトラック一覧取得
     * 認証済みユーザーのお気に入りトラック一覧をカーソルページネーションで取得する
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param limit 取得件数（省略時 20、最大 50） (optional)
     * @param cursor ページネーションカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse]
     */
    @GET("api/v1/users/me/track-favorites")
    suspend fun listTrackFavorites(@Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse>

    /**
     * トラックのお気に入り解除
     * 指定したトラックをお気に入りから削除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id トラックID（例: spotify:track:123）
     * @return [Unit]
     */
    @DELETE("api/v1/tracks/{id}/favorites")
    suspend fun removeTrackFavorite(@Path("id") id: kotlin.String): Response<Unit>

}
