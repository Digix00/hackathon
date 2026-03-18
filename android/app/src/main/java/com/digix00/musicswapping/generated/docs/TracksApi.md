# TracksApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getTrack**](TracksApi.md#getTrack) | **GET** api/v1/tracks/{id} | 楽曲詳細取得 |
| [**searchTracks**](TracksApi.md#searchTracks) | **GET** api/v1/tracks/search | 楽曲検索 |



楽曲詳細取得

連携済み音楽アカウント経由でトラック詳細を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(TracksApi::class.java)
val id : kotlin.String = id_example // kotlin.String | track id

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackResponse = webService.getTrack(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| track id | |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackResponse**](HackathonInternalHandlerSchemaResponseTrackResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


楽曲検索

連携済み Spotify アカウントを使ってトラック検索する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(TracksApi::class.java)
val q : kotlin.String = q_example // kotlin.String | query
val limit : kotlin.Int = 56 // kotlin.Int | limit (max 50)
val cursor : kotlin.String = cursor_example // kotlin.String | opaque cursor

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackSearchResponse = webService.searchTracks(q, limit, cursor)
}
```

### Parameters
| **q** | **kotlin.String**| query | |
| **limit** | **kotlin.Int**| limit (max 50) | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| opaque cursor | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackSearchResponse**](HackathonInternalHandlerSchemaResponseTrackSearchResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

