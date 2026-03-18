# MutesApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createMute**](MutesApi.md#createMute) | **POST** api/v1/users/me/mutes | ミュート作成 |
| [**deleteMute**](MutesApi.md#deleteMute) | **DELETE** api/v1/users/me/mutes/{target_user_id} | ミュート解除 |



ミュート作成

指定したユーザーをミュートする。自分自身や存在しないユーザーへのミュート、重複ミュートはエラーになる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MutesApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreateMuteRequest =  // HackathonInternalHandlerSchemaRequestCreateMuteRequest | ミュートリクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseMuteResponse = webService.createMute(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateMuteRequest**](HackathonInternalHandlerSchemaRequestCreateMuteRequest.md)| ミュートリクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseMuteResponse**](HackathonInternalHandlerSchemaResponseMuteResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


ミュート解除

指定したユーザーのミュートを解除する。ミュートが存在しない場合はエラーになる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(MutesApi::class.java)
val targetUserId : kotlin.String = targetUserId_example // kotlin.String | ミュート解除対象のユーザーID

launch(Dispatchers.IO) {
    webService.deleteMute(targetUserId)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **targetUserId** | **kotlin.String**| ミュート解除対象のユーザーID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

