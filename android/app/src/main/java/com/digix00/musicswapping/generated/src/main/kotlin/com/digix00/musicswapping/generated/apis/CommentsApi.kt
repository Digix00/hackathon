package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateCommentRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseCommentListResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseCommentResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface CommentsApi {
    /**
     * コメント作成
     * エンカウントにコメントを投稿する
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id エンカウント ID
     * @param body コメントリクエスト
     * @return [HackathonInternalHandlerSchemaResponseCommentResponse]
     */
    @POST("api/v1/encounters/{id}/comments")
    suspend fun createComment(@Path("id") id: kotlin.String, @Body body: HackathonInternalHandlerSchemaRequestCreateCommentRequest): Response<HackathonInternalHandlerSchemaResponseCommentResponse>

    /**
     * コメント削除
     * 自分のコメントを削除する
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id コメント ID
     * @return [Unit]
     */
    @DELETE("api/v1/comments/{id}")
    suspend fun deleteComment(@Path("id") id: kotlin.String): Response<Unit>

    /**
     * コメント一覧取得
     * エンカウントのコメント一覧を取得する
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id エンカウント ID
     * @param limit 取得件数（デフォルト: 20, 最大: 50） (optional)
     * @param cursor ページングカーソル (optional)
     * @return [HackathonInternalHandlerSchemaResponseCommentListResponse]
     */
    @GET("api/v1/encounters/{id}/comments")
    suspend fun listComments(@Path("id") id: kotlin.String, @Query("limit") limit: kotlin.Int? = null, @Query("cursor") cursor: kotlin.String? = null): Response<HackathonInternalHandlerSchemaResponseCommentListResponse>

}
