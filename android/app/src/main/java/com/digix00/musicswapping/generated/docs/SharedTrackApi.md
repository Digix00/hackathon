# SharedTrackApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**deleteSharedTrack**](SharedTrackApi.md#deleteSharedTrack) | **DELETE** api/v1/users/me/shared-track | シェア中の楽曲解除 |
| [**getSharedTrack**](SharedTrackApi.md#getSharedTrack) | **GET** api/v1/users/me/shared-track | シェア中の楽曲取得 |
| [**upsertSharedTrack**](SharedTrackApi.md#upsertSharedTrack) | **PUT** api/v1/users/me/shared-track | シェア中の楽曲設定・更新 |



シェア中の楽曲解除

認証済みユーザーのシェア中の楽曲を解除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SharedTrackApi::class.java)

launch(Dispatchers.IO) {
    webService.deleteSharedTrack()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


シェア中の楽曲取得

認証済みユーザーが現在シェア中の楽曲を取得する。未設定の場合は shared_track: null を返す。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SharedTrackApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseSharedTrackResponse = webService.getSharedTrack()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseSharedTrackResponse**](HackathonInternalHandlerSchemaResponseSharedTrackResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


シェア中の楽曲設定・更新

認証済みユーザーのシェア中の楽曲を設定または更新する。初回設定時は 201、更新時は 200。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SharedTrackApi::class.java)
val body : HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest =  // HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest | シェアトラック設定リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseSharedTrackResponse = webService.upsertSharedTrack(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest**](HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest.md)| シェアトラック設定リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseSharedTrackResponse**](HackathonInternalHandlerSchemaResponseSharedTrackResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

