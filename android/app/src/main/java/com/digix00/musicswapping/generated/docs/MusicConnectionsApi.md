# MusicConnectionsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**deleteMyMusicConnection**](MusicConnectionsApi.md#deleteMyMusicConnection) | **DELETE** api/v1/users/me/music-connections/{provider} | 音楽サービス連携解除 |
| [**getMusicAuthorizeURL**](MusicConnectionsApi.md#getMusicAuthorizeURL) | **GET** api/v1/music-connections/{provider}/authorize | 音楽サービス OAuth 認可 URL 取得 |
| [**getMyMusicConnections**](MusicConnectionsApi.md#getMyMusicConnections) | **GET** api/v1/users/me/music-connections | 音楽サービス連携一覧取得 |
| [**handleMusicCallback**](MusicConnectionsApi.md#handleMusicCallback) | **GET** api/v1/music-connections/{provider}/callback | 音楽サービス OAuth コールバック |



音楽サービス連携解除

指定プロバイダーの連携を解除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | spotify | apple_music

launch(Dispatchers.IO) {
    webService.deleteMyMusicConnection(provider)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **provider** | **kotlin.String**| spotify | apple_music | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


音楽サービス OAuth 認可 URL 取得

指定プロバイダーの OAuth 認可フローを開始し authorize_url を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | spotify | apple_music

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse = webService.getMusicAuthorizeURL(provider)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **provider** | **kotlin.String**| spotify | apple_music | |

### Return type

[**HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse**](HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


音楽サービス連携一覧取得

自分の音楽サービス連携一覧を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseMusicConnectionsResponse = webService.getMyMusicConnections()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseMusicConnectionsResponse**](HackathonInternalHandlerSchemaResponseMusicConnectionsResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


音楽サービス OAuth コールバック

OAuth コールバックを処理し、認可コードをトークンに交換してアプリへリダイレクト

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | spotify | apple_music
val code : kotlin.String = code_example // kotlin.String | 認可コード
val state : kotlin.String = state_example // kotlin.String | CSRF state

launch(Dispatchers.IO) {
    webService.handleMusicCallback(provider, code, state)
}
```

### Parameters
| **provider** | **kotlin.String**| spotify | apple_music | |
| **code** | **kotlin.String**| 認可コード | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **state** | **kotlin.String**| CSRF state | |

### Return type

null (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

