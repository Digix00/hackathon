# BlocksAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createBlock**](BlocksAPI.md#createblock) | **POST** /api/v1/users/me/blocks | ブロック作成
[**deleteBlock**](BlocksAPI.md#deleteblock) | **DELETE** /api/v1/users/me/blocks/{blocked_user_id} | ブロック解除
[**listBlocks**](BlocksAPI.md#listblocks) | **GET** /api/v1/users/me/blocks | ブロック一覧取得


# **createBlock**
```swift
    open class func createBlock(body: HackathonInternalHandlerSchemaRequestCreateBlockRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseBlockResponse?, _ error: Error?) -> Void)
```

ブロック作成

指定したユーザーをブロックする。自分自身や存在しないユーザーへのブロック、重複ブロックはエラーになる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreateBlockRequest(blockedUserId: "blockedUserId_example") // HackathonInternalHandlerSchemaRequestCreateBlockRequest | ブロックリクエスト

// ブロック作成
BlocksAPI.createBlock(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreateBlockRequest**](HackathonInternalHandlerSchemaRequestCreateBlockRequest.md) | ブロックリクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseBlockResponse**](HackathonInternalHandlerSchemaResponseBlockResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteBlock**
```swift
    open class func deleteBlock(blockedUserId: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

ブロック解除

指定したユーザーのブロックを解除する。ブロックが存在しない場合はエラーになる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let blockedUserId = "blockedUserId_example" // String | ブロック解除対象のユーザーID

// ブロック解除
BlocksAPI.deleteBlock(blockedUserId: blockedUserId) { (response, error) in
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
 **blockedUserId** | **String** | ブロック解除対象のユーザーID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBlocks**
```swift
    open class func listBlocks(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseBlockListResponse?, _ error: Error?) -> Void)
```

ブロック一覧取得

認証済みユーザーがブロックしているユーザーの一覧をカーソルページネーションで取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20、最大 50） (optional)
let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// ブロック一覧取得
BlocksAPI.listBlocks(limit: limit, cursor: cursor) { (response, error) in
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
 **limit** | **Int** | 取得件数（省略時 20、最大 50） | [optional] 
 **cursor** | **String** | ページネーションカーソル | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseBlockListResponse**](HackathonInternalHandlerSchemaResponseBlockListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

