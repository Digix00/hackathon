# MusicConnectionsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**deleteMusicConnection**](MusicConnectionsApi.md#deleteMusicConnection) | **DELETE** api/v1/users/me/music-connections/{provider} | 音楽連携を解除 |
| [**getMusicAuthorizeURL**](MusicConnectionsApi.md#getMusicAuthorizeURL) | **GET** api/v1/music-connections/{provider}/authorize | 音楽サービス連携の認可 URL を取得 |
| [**handleMusicCallback**](MusicConnectionsApi.md#handleMusicCallback) | **GET** api/v1/music-connections/{provider}/callback | 音楽サービス連携のコールバック |
| [**listMusicConnections**](MusicConnectionsApi.md#listMusicConnections) | **GET** api/v1/users/me/music-connections | 自分の音楽連携一覧を取得 |



音楽連携を解除

指定 provider の音楽連携を解除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | provider

launch(Dispatchers.IO) {
    webService.deleteMusicConnection(provider)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **provider** | **kotlin.String**| provider | [enum: spotify, apple_music] |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


音楽サービス連携の認可 URL を取得

Spotify / Apple Music の OAuth 認可開始 URL と state を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | provider

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse = webService.getMusicAuthorizeURL(provider)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **provider** | **kotlin.String**| provider | [enum: spotify, apple_music] |

### Return type

[**HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse**](HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


音楽サービス連携のコールバック

OAuth コールバックを処理し、アプリ deep link へリダイレクトする

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)
val provider : kotlin.String = provider_example // kotlin.String | provider
val code : kotlin.String = code_example // kotlin.String | authorization code
val state : kotlin.String = state_example // kotlin.String | signed state

launch(Dispatchers.IO) {
    webService.handleMusicCallback(provider, code, state)
}
```

### Parameters
| **provider** | **kotlin.String**| provider | [enum: spotify, apple_music] |
| **code** | **kotlin.String**| authorization code | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **state** | **kotlin.String**| signed state | |

### Return type

null (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


自分の音楽連携一覧を取得

連携済み Spotify / Apple Music アカウント一覧を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MusicConnectionsApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseMusicConnectionsResponse = webService.listMusicConnections()
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

