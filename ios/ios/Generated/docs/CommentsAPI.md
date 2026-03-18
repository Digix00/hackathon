# CommentsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createComment**](CommentsAPI.md#createcomment) | **POST** /api/v1/encounters/{id}/comments | コメント作成
[**deleteComment**](CommentsAPI.md#deletecomment) | **DELETE** /api/v1/comments/{id} | コメント削除
[**listComments**](CommentsAPI.md#listcomments) | **GET** /api/v1/encounters/{id}/comments | コメント一覧取得


# **createComment**
```swift
    open class func createComment(id: String, body: HackathonInternalHandlerSchemaRequestCreateCommentRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseCommentResponse?, _ error: Error?) -> Void)
```

コメント作成

エンカウントにコメントを投稿する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | エンカウント ID
let body = hackathon_internal_handler_schema_request.CreateCommentRequest(content: "content_example") // HackathonInternalHandlerSchemaRequestCreateCommentRequest | コメントリクエスト

// コメント作成
CommentsAPI.createComment(id: id, body: body) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** | エンカウント ID | 
 **body** | [**HackathonInternalHandlerSchemaRequestCreateCommentRequest**](HackathonInternalHandlerSchemaRequestCreateCommentRequest.md) | コメントリクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseCommentResponse**](HackathonInternalHandlerSchemaResponseCommentResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteComment**
```swift
    open class func deleteComment(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

コメント削除

自分のコメントを削除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | コメント ID

// コメント削除
CommentsAPI.deleteComment(id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** | コメント ID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listComments**
```swift
    open class func listComments(id: String, limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseCommentListResponse?, _ error: Error?) -> Void)
```

コメント一覧取得

エンカウントのコメント一覧を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | エンカウント ID
let limit = 987 // Int | 取得件数（デフォルト: 20, 最大: 50） (optional)
let cursor = "cursor_example" // String | ページングカーソル (optional)

// コメント一覧取得
CommentsAPI.listComments(id: id, limit: limit, cursor: cursor) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** | エンカウント ID | 
 **limit** | **Int** | 取得件数（デフォルト: 20, 最大: 50） | [optional] 
 **cursor** | **String** | ページングカーソル | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseCommentListResponse**](HackathonInternalHandlerSchemaResponseCommentListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

