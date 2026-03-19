# SongsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**likeSong**](SongsApi.md#likeSong) | **POST** api/v1/songs/{id}/likes | 楽曲にいいね |
| [**listMySongs**](SongsApi.md#listMySongs) | **GET** api/v1/users/me/songs | 自分が参加した楽曲一覧 |
| [**unlikeSong**](SongsApi.md#unlikeSong) | **DELETE** api/v1/songs/{id}/likes | 楽曲のいいねを取り消す |



楽曲にいいね

指定した楽曲にいいねする。すでにいいね済みの場合はエラー。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SongsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 楽曲ID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseLikeSongResponse = webService.likeSong(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 楽曲ID | |

### Return type

[**HackathonInternalHandlerSchemaResponseLikeSongResponse**](HackathonInternalHandlerSchemaResponseLikeSongResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


自分が参加した楽曲一覧

自分がLyricChainに参加して生成された楽曲の一覧を返す。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SongsApi::class.java)
val cursor : kotlin.String = cursor_example // kotlin.String | ページネーションカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseListUserSongsResponse = webService.listMySongs(cursor)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| ページネーションカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseListUserSongsResponse**](HackathonInternalHandlerSchemaResponseListUserSongsResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


楽曲のいいねを取り消す

指定した楽曲のいいねを取り消す。いいねが存在しない場合はエラー。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SongsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 楽曲ID

launch(Dispatchers.IO) {
    webService.unlikeSong(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 楽曲ID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

