# FavoritesApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**addTrackFavorite**](FavoritesApi.md#addTrackFavorite) | **POST** api/v1/tracks/{id}/favorites | トラックをお気に入り登録 |
| [**listPlaylistFavorites**](FavoritesApi.md#listPlaylistFavorites) | **GET** api/v1/users/me/playlist-favorites | お気に入りプレイリスト一覧取得 |
| [**listTrackFavorites**](FavoritesApi.md#listTrackFavorites) | **GET** api/v1/users/me/track-favorites | お気に入りトラック一覧取得 |
| [**removeTrackFavorite**](FavoritesApi.md#removeTrackFavorite) | **DELETE** api/v1/tracks/{id}/favorites | トラックのお気に入り解除 |



トラックをお気に入り登録

指定したトラックをお気に入りに追加する。既にお気に入り済みの場合はべき等に処理し 200 を返す。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(FavoritesApi::class.java)
val id : kotlin.String = id_example // kotlin.String | トラックID（例: spotify:track:123）

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackFavoriteResponse = webService.addTrackFavorite(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| トラックID（例: spotify:track:123） | |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackFavoriteResponse**](HackathonInternalHandlerSchemaResponseTrackFavoriteResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


お気に入りプレイリスト一覧取得

認証済みユーザーのお気に入りプレイリスト一覧をカーソルページネーションで取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(FavoritesApi::class.java)
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（省略時 20、最大 50）
val cursor : kotlin.String = cursor_example // kotlin.String | ページネーションカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse = webService.listPlaylistFavorites(limit, cursor)
}
```

### Parameters
| **limit** | **kotlin.Int**| 取得件数（省略時 20、最大 50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| ページネーションカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse**](HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


お気に入りトラック一覧取得

認証済みユーザーのお気に入りトラック一覧をカーソルページネーションで取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(FavoritesApi::class.java)
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（省略時 20、最大 50）
val cursor : kotlin.String = cursor_example // kotlin.String | ページネーションカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse = webService.listTrackFavorites(limit, cursor)
}
```

### Parameters
| **limit** | **kotlin.Int**| 取得件数（省略時 20、最大 50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| ページネーションカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse**](HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


トラックのお気に入り解除

指定したトラックをお気に入りから削除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(FavoritesApi::class.java)
val id : kotlin.String = id_example // kotlin.String | トラックID（例: spotify:track:123）

launch(Dispatchers.IO) {
    webService.removeTrackFavorite(id)
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

