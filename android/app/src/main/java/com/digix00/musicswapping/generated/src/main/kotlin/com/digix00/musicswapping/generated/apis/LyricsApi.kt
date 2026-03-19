package com.digix00.musicswapping.generated.apis

import com.digix00.musicswapping.generated.infrastructure.CollectionFormats.*
import retrofit2.http.*
import retrofit2.Response
import okhttp3.RequestBody
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaRequestSubmitLyricRequest
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseChainDetailResponse
import com.digix00.musicswapping.generated.models.HackathonInternalHandlerSchemaResponseSubmitLyricResponse
import com.digix00.musicswapping.generated.models.InternalHandlererrorResponse

interface LyricsApi {
    /**
     * チェーン詳細取得
     * チェーンの詳細と参加者の歌詞一覧、生成楽曲を取得する。
     * Responses:
     *  - 200: OK
     *  - 401: Unauthorized
     *  - 404: Not Found
     *  - 500: Internal Server Error
     *
     * @param chainId チェーンID
     * @return [HackathonInternalHandlerSchemaResponseChainDetailResponse]
     */
    @GET("api/v1/lyrics/chains/{chain_id}")
    suspend fun getChainDetail(@Path("chain_id") chainId: kotlin.String): Response<HackathonInternalHandlerSchemaResponseChainDetailResponse>

    /**
     * 歌詞投稿
     * すれ違い成立時に歌詞を投稿し、LyricChainに追加する。
     * Responses:
     *  - 201: Created
     *  - 400: Bad Request
     *  - 401: Unauthorized
     *  - 500: Internal Server Error
     *
     * @param body 歌詞投稿リクエスト
     * @return [HackathonInternalHandlerSchemaResponseSubmitLyricResponse]
     */
    @POST("api/v1/lyrics")
    suspend fun submitLyric(@Body body: HackathonInternalHandlerSchemaRequestSubmitLyricRequest): Response<HackathonInternalHandlerSchemaResponseSubmitLyricResponse>

}
