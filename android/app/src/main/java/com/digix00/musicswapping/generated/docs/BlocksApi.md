# BlocksApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createBlock**](BlocksApi.md#createBlock) | **POST** api/v1/users/me/blocks | ブロック作成 |
| [**deleteBlock**](BlocksApi.md#deleteBlock) | **DELETE** api/v1/users/me/blocks/{blocked_user_id} | ブロック解除 |



ブロック作成

指定したユーザーをブロックする。自分自身や存在しないユーザーへのブロック、重複ブロックはエラーになる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(BlocksApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreateBlockRequest =  // HackathonInternalHandlerSchemaRequestCreateBlockRequest | ブロックリクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseBlockResponse = webService.createBlock(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateBlockRequest**](HackathonInternalHandlerSchemaRequestCreateBlockRequest.md)| ブロックリクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseBlockResponse**](HackathonInternalHandlerSchemaResponseBlockResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


ブロック解除

指定したユーザーのブロックを解除する。ブロックが存在しない場合はエラーになる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(BlocksApi::class.java)
val blockedUserId : kotlin.String = blockedUserId_example // kotlin.String | ブロック解除対象のユーザーID

launch(Dispatchers.IO) {
    webService.deleteBlock(blockedUserId)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **blockedUserId** | **kotlin.String**| ブロック解除対象のユーザーID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

