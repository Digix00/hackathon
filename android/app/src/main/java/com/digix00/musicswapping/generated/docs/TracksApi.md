# TracksApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getTrack**](TracksApi.md#getTrack) | **GET** api/v1/tracks/{id} | トラック詳細取得 |
| [**searchTracks**](TracksApi.md#searchTracks) | **GET** api/v1/tracks/search | トラック検索 |



トラック詳細取得

指定トラックの詳細を返す（ID: &lt;provider&gt;:track:&lt;external_id&gt;）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(TracksApi::class.java)
val id : kotlin.String = id_example // kotlin.String | トラック ID（例: spotify:track:123）

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackDetailResponse = webService.getTrack(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| トラック ID（例: spotify:track:123） | |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackDetailResponse**](HackathonInternalHandlerSchemaResponseTrackDetailResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


トラック検索

Spotify Web API にプロキシするトラック検索

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(TracksApi::class.java)
val q : kotlin.String = q_example // kotlin.String | 検索キーワード
val limit : kotlin.Int = 56 // kotlin.Int | 件数（省略時20、最大50）
val cursor : kotlin.String = cursor_example // kotlin.String | 次ページカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackSearchResponse = webService.searchTracks(q, limit, cursor)
}
```

### Parameters
| **q** | **kotlin.String**| 検索キーワード | |
| **limit** | **kotlin.Int**| 件数（省略時20、最大50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| 次ページカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackSearchResponse**](HackathonInternalHandlerSchemaResponseTrackSearchResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

