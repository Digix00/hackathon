# CommentsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createComment**](CommentsApi.md#createComment) | **POST** api/v1/encounters/{id}/comments | コメント作成 |
| [**deleteComment**](CommentsApi.md#deleteComment) | **DELETE** api/v1/comments/{id} | コメント削除 |
| [**listComments**](CommentsApi.md#listComments) | **GET** api/v1/encounters/{id}/comments | コメント一覧取得 |



コメント作成

エンカウントにコメントを投稿する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(CommentsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | エンカウント ID
val body : HackathonInternalHandlerSchemaRequestCreateCommentRequest =  // HackathonInternalHandlerSchemaRequestCreateCommentRequest | コメントリクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseCommentResponse = webService.createComment(id, body)
}
```

### Parameters
| **id** | **kotlin.String**| エンカウント ID | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateCommentRequest**](HackathonInternalHandlerSchemaRequestCreateCommentRequest.md)| コメントリクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseCommentResponse**](HackathonInternalHandlerSchemaResponseCommentResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


コメント削除

自分のコメントを削除する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(CommentsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | コメント ID

launch(Dispatchers.IO) {
    webService.deleteComment(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| コメント ID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


コメント一覧取得

エンカウントのコメント一覧を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(CommentsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | エンカウント ID
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（デフォルト: 20, 最大: 50）
val cursor : kotlin.String = cursor_example // kotlin.String | ページングカーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseCommentListResponse = webService.listComments(id, limit, cursor)
}
```

### Parameters
| **id** | **kotlin.String**| エンカウント ID | |
| **limit** | **kotlin.Int**| 取得件数（デフォルト: 20, 最大: 50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| ページングカーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseCommentListResponse**](HackathonInternalHandlerSchemaResponseCommentListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

