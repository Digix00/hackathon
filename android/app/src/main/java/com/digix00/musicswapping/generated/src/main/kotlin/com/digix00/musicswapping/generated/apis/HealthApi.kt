package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable


interface HealthApi {
    /**
     * ヘルスチェック
     * サーバーが起動しているか確認する
     * Responses:
     *  - 200: OK
     *
     * @return [kotlin.collections.Map<kotlin.String, kotlin.String>]
     */
    @GET("healthz")
    suspend fun healthz(): Response<kotlin.collections.Map<kotlin.String, kotlin.String>>

    /**
     * PostgreSQL ヘルスチェック
     * PostgreSQL への接続を確認する（タイムアウト 5s）
     * Responses:
     *  - 200: OK
     *  - 503: Service Unavailable
     *
     * @return [kotlin.collections.Map<kotlin.String, kotlin.String>]
     */
    @GET("healthz/postgres")
    suspend fun healthzPostgres(): Response<kotlin.collections.Map<kotlin.String, kotlin.String>>

}
