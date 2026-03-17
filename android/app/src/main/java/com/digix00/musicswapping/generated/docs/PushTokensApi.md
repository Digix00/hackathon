# PushTokensApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createPushToken**](PushTokensApi.md#createPushToken) | **POST** api/v1/users/me/push-tokens | プッシュトークン登録（upsert） |
| [**deletePushToken**](PushTokensApi.md#deletePushToken) | **DELETE** api/v1/users/me/push-tokens/{id} | プッシュトークン削除 |
| [**patchPushToken**](PushTokensApi.md#patchPushToken) | **PATCH** api/v1/users/me/push-tokens/{id} | プッシュトークン更新 |



プッシュトークン登録（upsert）

device_id が既存なら更新して 200、新規なら 201 を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PushTokensApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreatePushTokenRequest =  // HackathonInternalHandlerSchemaRequestCreatePushTokenRequest | プッシュトークン登録リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseDeviceResponse = webService.createPushToken(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreatePushTokenRequest**](HackathonInternalHandlerSchemaRequestCreatePushTokenRequest.md)| プッシュトークン登録リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseDeviceResponse**](HackathonInternalHandlerSchemaResponseDeviceResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


プッシュトークン削除

指定デバイスのレコードを削除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PushTokensApi::class.java)
val id : kotlin.String = id_example // kotlin.String | デバイス ID

launch(Dispatchers.IO) {
    webService.deletePushToken(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| デバイス ID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


プッシュトークン更新

指定デバイスのトークン・有効フラグ・アプリバージョンを部分更新する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(PushTokensApi::class.java)
val id : kotlin.String = id_example // kotlin.String | デバイス ID
val body : HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest =  // HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest | プッシュトークン更新リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseDeviceResponse = webService.patchPushToken(id, body)
}
```

### Parameters
| **id** | **kotlin.String**| デバイス ID | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest**](HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest.md)| プッシュトークン更新リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseDeviceResponse**](HackathonInternalHandlerSchemaResponseDeviceResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

