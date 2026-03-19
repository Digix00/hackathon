# LocationsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**postLocation**](LocationsApi.md#postLocation) | **POST** api/v1/locations | 現在位置送信・エンカウント判定 |



現在位置送信・エンカウント判定

現在位置をサーバーに送信し、近くにいるユーザーとのエンカウントを判定・作成する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LocationsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestPostLocationRequest =  // HackathonInternalHandlerSchemaRequestPostLocationRequest | 位置情報リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseLocationResponse = webService.postLocation(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestPostLocationRequest**](HackathonInternalHandlerSchemaRequestPostLocationRequest.md)| 位置情報リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseLocationResponse**](HackathonInternalHandlerSchemaResponseLocationResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

