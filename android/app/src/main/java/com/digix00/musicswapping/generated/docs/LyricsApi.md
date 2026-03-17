# LyricsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getLyricChain**](LyricsApi.md#getLyricChain) | **GET** api/v1/lyrics/chains/{chain_id} | 歌詞チェーン詳細取得 |
| [**postLyric**](LyricsApi.md#postLyric) | **POST** api/v1/lyrics | 歌詞投稿 |



歌詞チェーン詳細取得

チェーンの詳細と全歌詞エントリを返す。completed 時のみ song フィールドが含まれる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LyricsApi::class.java)
val chainId : kotlin.String = chainId_example // kotlin.String | チェーン ID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseLyricChainDetailResponse = webService.getLyricChain(chainId)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **chainId** | **kotlin.String**| チェーン ID | |

### Return type

[**HackathonInternalHandlerSchemaResponseLyricChainDetailResponse**](HackathonInternalHandlerSchemaResponseLyricChainDetailResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


歌詞投稿

エンカウントをきっかけに歌詞チェーンへ1行を投稿する。チェーンが threshold に達すると楽曲生成ジョブが登録される。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LyricsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestPostLyricRequest =  // HackathonInternalHandlerSchemaRequestPostLyricRequest | 歌詞投稿リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePostLyricResponse = webService.postLyric(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestPostLyricRequest**](HackathonInternalHandlerSchemaRequestPostLyricRequest.md)| 歌詞投稿リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponsePostLyricResponse**](HackathonInternalHandlerSchemaResponsePostLyricResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

