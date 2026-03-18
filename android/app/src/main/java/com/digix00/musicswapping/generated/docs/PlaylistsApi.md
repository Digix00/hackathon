# PlaylistsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**addPlaylistFavorite**](PlaylistsApi.md#addPlaylistFavorite) | **POST** api/v1/playlists/{id}/favorites | プレイリストをお気に入り登録 |
| [**addPlaylistTrack**](PlaylistsApi.md#addPlaylistTrack) | **POST** api/v1/playlists/{id}/tracks | プレイリストにトラック追加 |
| [**createPlaylist**](PlaylistsApi.md#createPlaylist) | **POST** api/v1/playlists | プレイリスト作成 |
| [**deletePlaylist**](PlaylistsApi.md#deletePlaylist) | **DELETE** api/v1/playlists/{id} | プレイリスト削除 |
| [**getMyPlaylists**](PlaylistsApi.md#getMyPlaylists) | **GET** api/v1/playlists/me | 自分のプレイリスト一覧取得 |
| [**getPlaylist**](PlaylistsApi.md#getPlaylist) | **GET** api/v1/playlists/{id} | プレイリスト取得 |
| [**removePlaylistFavorite**](PlaylistsApi.md#removePlaylistFavorite) | **DELETE** api/v1/playlists/{id}/favorites | プレイリストのお気に入り解除 |
| [**removePlaylistTrack**](PlaylistsApi.md#removePlaylistTrack) | **DELETE** api/v1/playlists/{id}/tracks/{trackId} | プレイリストからトラック削除 |
| [**updatePlaylist**](PlaylistsApi.md#updatePlaylist) | **PATCH** api/v1/playlists/{id} | プレイリスト更新 |



プレイリストをお気に入り登録

指定したプレイリストをお気に入りに追加する（公開プレイリストのみ、または所有者）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID

launch(Dispatchers.IO) {
    webService.addPlaylistFavorite(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| プレイリストID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


プレイリストにトラック追加

プレイリストにトラックを追加する（所有者のみ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID
val body : HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest =  // HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest | トラック追加リクエスト

launch(Dispatchers.IO) {
    webService.addPlaylistTrack(id, body)
}
```

### Parameters
| **id** | **kotlin.String**| プレイリストID | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest**](HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest.md)| トラック追加リクエスト | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


プレイリスト作成

認証済みユーザーの新規プレイリストを作成する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreatePlaylistRequest =  // HackathonInternalHandlerSchemaRequestCreatePlaylistRequest | プレイリスト作成リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePlaylistResponse = webService.createPlaylist(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreatePlaylistRequest**](HackathonInternalHandlerSchemaRequestCreatePlaylistRequest.md)| プレイリスト作成リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


プレイリスト削除

プレイリストを削除する（所有者のみ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID

launch(Dispatchers.IO) {
    webService.deletePlaylist(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| プレイリストID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


自分のプレイリスト一覧取得

認証済みユーザー自身のプレイリスト一覧を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePlaylistListResponse = webService.getMyPlaylists()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistListResponse**](HackathonInternalHandlerSchemaResponsePlaylistListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


プレイリスト取得

指定したプレイリストをトラック情報付きで取得する（公開プレイリストは誰でも取得可能、非公開は所有者のみ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePlaylistResponse = webService.getPlaylist(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| プレイリストID | |

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


プレイリストのお気に入り解除

指定したプレイリストをお気に入りから削除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID

launch(Dispatchers.IO) {
    webService.removePlaylistFavorite(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| プレイリストID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


プレイリストからトラック削除

プレイリストからトラックを削除する（所有者のみ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID
val trackId : kotlin.String = trackId_example // kotlin.String | トラックID

launch(Dispatchers.IO) {
    webService.removePlaylistTrack(id, trackId)
}
```

### Parameters
| **id** | **kotlin.String**| プレイリストID | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **trackId** | **kotlin.String**| トラックID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


プレイリスト更新

プレイリストの名前・説明・公開設定を更新する（所有者のみ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PlaylistsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | プレイリストID
val body : HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest =  // HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest | プレイリスト更新リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePlaylistResponse = webService.updatePlaylist(id, body)
}
```

### Parameters
| **id** | **kotlin.String**| プレイリストID | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest**](HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest.md)| プレイリスト更新リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

