package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestCreateUserRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestUpdateUserRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponsePublicUserResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseUserResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

import okhttp3.MultipartBody

interface UsersApi {
    /**
     * ユーザー作成
     * Firebase 認証済みの新規ユーザーを登録する（初回ログイン時に一度だけ呼ぶ）
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 409: Conflict
     *  - 500: Internal Server Error
     *
     * @param body ユーザー作成リクエスト
     * @return [HackathonInternalHandlerSchemaResponseUserResponse]
     */
    @POST("api/v1/users")
    suspend fun createUser(@Body body: HackathonInternalHandlerSchemaRequestCreateUserRequest): Response<HackathonInternalHandlerSchemaResponseUserResponse>

    /**
     * 自分のアカウント削除
     * DB レコードと Firebase アカウントを削除する（Firebase 削除はベストエフォート）
     * Responses:
     *  - 204: No Content
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [Unit]
     */
    @DELETE("api/v1/users/me")
    suspend fun deleteMe(): Response<Unit>

    /**
     * 自分のユーザー情報取得
     * 認証中のユーザー自身のプロフィールを返す
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @return [HackathonInternalHandlerSchemaResponseUserResponse]
     */
    @GET("api/v1/users/me")
    suspend fun getMe(): Response<HackathonInternalHandlerSchemaResponseUserResponse>

    /**
     * 他ユーザーのプロフィール取得
     * 指定した ID の公開プロフィールを返す
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 403: Forbidden
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param id 対象ユーザー ID
     * @return [HackathonInternalHandlerSchemaResponsePublicUserResponse]
     */
    @GET("api/v1/users/{id}")
    suspend fun getUserByID(@Path("id") id: kotlin.String): Response<HackathonInternalHandlerSchemaResponsePublicUserResponse>

    /**
     * 自分のプロフィール更新
     * 指定したフィールドだけを部分更新する（null フィールドは変更しない）
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param body プロフィール更新リクエスト
     * @return [HackathonInternalHandlerSchemaResponseUserResponse]
     */
    @PATCH("api/v1/users/me")
    suspend fun patchMe(@Body body: HackathonInternalHandlerSchemaRequestUpdateUserRequest): Response<HackathonInternalHandlerSchemaResponseUserResponse>

    /**
     * アバター画像アップロード
     * multipart/form-data でアバター画像を受け取り GCS にアップロードして公開 URL を返す。DB 更新は行わないため、呼び出し後に PATCH /users/me で avatar_url を保存すること。
     * Responses:
     *  - 200: OK
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *  - 503: Service Unavailable
     *
     * @param file アバター画像（JPEG または PNG、最大 5MB）
     * @return [kotlin.collections.Map<kotlin.String, kotlin.String>]
     */
    @Multipart
    @POST("api/v1/users/me/avatar")
    suspend fun uploadAvatar(@Part file: MultipartBody.Part): Response<kotlin.collections.Map<kotlin.String, kotlin.String>>

}
