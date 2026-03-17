# SettingsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**getMySettings**](SettingsApi.md#getMySettings) | **GET** api/v1/users/me/settings | 自分の設定取得 |
| [**patchMySettings**](SettingsApi.md#patchMySettings) | **PATCH** api/v1/users/me/settings | 自分の設定更新 |



自分の設定取得

認証中のユーザーのアプリ設定を返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SettingsApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseSettingsResponse = webService.getMySettings()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseSettingsResponse**](HackathonInternalHandlerSchemaResponseSettingsResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


自分の設定更新

指定したフィールドだけを部分更新する（null フィールドは変更しない）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(SettingsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestUpdateSettingsRequest =  // HackathonInternalHandlerSchemaRequestUpdateSettingsRequest | 設定更新リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseSettingsResponse = webService.patchMySettings(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestUpdateSettingsRequest**](HackathonInternalHandlerSchemaRequestUpdateSettingsRequest.md)| 設定更新リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseSettingsResponse**](HackathonInternalHandlerSchemaResponseSettingsResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

