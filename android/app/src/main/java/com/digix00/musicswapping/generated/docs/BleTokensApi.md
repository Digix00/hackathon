# BleTokensApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createBleToken**](BleTokensApi.md#createBleToken) | **POST** api/v1/ble-tokens | BLE トークン発行 |
| [**getCurrentBleToken**](BleTokensApi.md#getCurrentBleToken) | **GET** api/v1/ble-tokens/current | 有効な BLE トークン取得 |
| [**getUserByBleToken**](BleTokensApi.md#getUserByBleToken) | **GET** api/v1/ble-tokens/{token}/user | BLE トークンからユーザー情報取得 |



BLE トークン発行

現在ログインしているユーザーの新規 BLE トークンを発行する（24時間有効）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(BleTokensApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseBleTokenResponse = webService.createBleToken()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseBleTokenResponse**](HackathonInternalHandlerSchemaResponseBleTokenResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


有効な BLE トークン取得

現在ログインしているユーザーの有効な最新の BLE トークンを取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(BleTokensApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseBleTokenResponse = webService.getCurrentBleToken()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseBleTokenResponse**](HackathonInternalHandlerSchemaResponseBleTokenResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


BLE トークンからユーザー情報取得

指定した BLE トークンに紐づくユーザーの公開プロフィールを取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(BleTokensApi::class.java)
val token : kotlin.String = token_example // kotlin.String | 対象の BLE トークン

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseBleTokenUserResponse = webService.getUserByBleToken(token)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **token** | **kotlin.String**| 対象の BLE トークン | |

### Return type

[**HackathonInternalHandlerSchemaResponseBleTokenUserResponse**](HackathonInternalHandlerSchemaResponseBleTokenUserResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

