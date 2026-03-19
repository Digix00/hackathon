# LyricsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getChainDetail**](LyricsApi.md#getChainDetail) | **GET** api/v1/lyrics/chains/{chain_id} | チェーン詳細取得 |
| [**submitLyric**](LyricsApi.md#submitLyric) | **POST** api/v1/lyrics | 歌詞投稿 |



チェーン詳細取得

チェーンの詳細と参加者の歌詞一覧、生成楽曲を取得する。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LyricsApi::class.java)
val chainId : kotlin.String = chainId_example // kotlin.String | チェーンID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseChainDetailResponse = webService.getChainDetail(chainId)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **chainId** | **kotlin.String**| チェーンID | |

### Return type

[**HackathonInternalHandlerSchemaResponseChainDetailResponse**](HackathonInternalHandlerSchemaResponseChainDetailResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


歌詞投稿

すれ違い成立時に歌詞を投稿し、LyricChainに追加する。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LyricsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestSubmitLyricRequest =  // HackathonInternalHandlerSchemaRequestSubmitLyricRequest | 歌詞投稿リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseSubmitLyricResponse = webService.submitLyric(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestSubmitLyricRequest**](HackathonInternalHandlerSchemaRequestSubmitLyricRequest.md)| 歌詞投稿リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseSubmitLyricResponse**](HackathonInternalHandlerSchemaResponseSubmitLyricResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

