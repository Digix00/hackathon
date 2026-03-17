package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestPostLyricRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseLyricChainDetailResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponsePostLyricResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface LyricsApi {
    /**
     * 歌詞チェーン詳細取得
     * チェーンの詳細と全歌詞エントリを返す。completed 時のみ song フィールドが含まれる。
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *
     * @param chainId チェーン ID
     * @return [HackathonInternalHandlerSchemaResponseLyricChainDetailResponse]
     */
    @GET("api/v1/lyrics/chains/{chain_id}")
    suspend fun getLyricChain(@Path("chain_id") chainId: kotlin.String): Response<HackathonInternalHandlerSchemaResponseLyricChainDetailResponse>

    /**
     * 歌詞投稿
     * エンカウントをきっかけに歌詞チェーンへ1行を投稿する。チェーンが threshold に達すると楽曲生成ジョブが登録される。
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 409: Conflict
     *
     * @param body 歌詞投稿リクエスト
     * @return [HackathonInternalHandlerSchemaResponsePostLyricResponse]
     */
    @POST("api/v1/lyrics")
    suspend fun postLyric(@Body body: HackathonInternalHandlerSchemaRequestPostLyricRequest): Response<HackathonInternalHandlerSchemaResponsePostLyricResponse>

}
