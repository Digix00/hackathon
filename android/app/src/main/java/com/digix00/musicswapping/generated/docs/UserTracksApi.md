# UserTracksApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**addUserTrack**](UserTracksApi.md#addUserTrack) | **POST** api/v1/users/me/tracks | マイトラックに楽曲追加 |
| [**deleteUserTrack**](UserTracksApi.md#deleteUserTrack) | **DELETE** api/v1/users/me/tracks/{id} | マイトラックから楽曲削除 |
| [**listUserTracks**](UserTracksApi.md#listUserTracks) | **GET** api/v1/users/me/tracks | マイトラック一覧取得 |



マイトラックに楽曲追加

認証済みユーザーのマイトラックに楽曲を追加する。既に登録済みの場合は 200 を返す。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UserTracksApi::class.java)
val body : HackathonInternalHandlerSchemaRequestAddUserTrackRequest =  // HackathonInternalHandlerSchemaRequestAddUserTrackRequest | トラック追加リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseUserTrackResponse = webService.addUserTrack(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestAddUserTrackRequest**](HackathonInternalHandlerSchemaRequestAddUserTrackRequest.md)| トラック追加リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseUserTrackResponse**](HackathonInternalHandlerSchemaResponseUserTrackResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


マイトラックから楽曲削除

認証済みユーザーのマイトラックから楽曲を削除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UserTracksApi::class.java)
val id : kotlin.String = id_example // kotlin.String | トラックID（例: spotify:track:123）

launch(Dispatchers.IO) {
    webService.deleteUserTrack(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| トラックID（例: spotify:track:123） | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


マイトラック一覧取得

認証済みユーザーのマイトラック一覧をカーソルページネーションで取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UserTracksApi::class.java)
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（省略時 20、最大 50）
val cursor : kotlin.String = cursor_example // kotlin.String | ページネーションカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseUserTrackListResponse = webService.listUserTracks(limit, cursor)
}
```

### Parameters
| **limit** | **kotlin.Int**| 取得件数（省略時 20、最大 50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| ページネーションカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseUserTrackListResponse**](HackathonInternalHandlerSchemaResponseUserTrackListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

