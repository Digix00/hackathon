# MutesAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMute**](MutesAPI.md#createmute) | **POST** /api/v1/users/me/mutes | ミュート作成
[**deleteMute**](MutesAPI.md#deletemute) | **DELETE** /api/v1/users/me/mutes/{target_user_id} | ミュート解除
[**listMutes**](MutesAPI.md#listmutes) | **GET** /api/v1/users/me/mutes | ミュート一覧取得


# **createMute**
```swift
    open class func createMute(body: HackathonInternalHandlerSchemaRequestCreateMuteRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMuteResponse?, _ error: Error?) -> Void)
```

ミュート作成

指定したユーザーをミュートする。自分自身や存在しないユーザーへのミュート、重複ミュートはエラーになる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreateMuteRequest(targetUserId: "targetUserId_example") // HackathonInternalHandlerSchemaRequestCreateMuteRequest | ミュートリクエスト

// ミュート作成
MutesAPI.createMute(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreateMuteRequest**](HackathonInternalHandlerSchemaRequestCreateMuteRequest.md) | ミュートリクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseMuteResponse**](HackathonInternalHandlerSchemaResponseMuteResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMute**
```swift
    open class func deleteMute(targetUserId: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

ミュート解除

指定したユーザーのミュートを解除する。ミュートが存在しない場合はエラーになる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let targetUserId = "targetUserId_example" // String | ミュート解除対象のユーザーID

// ミュート解除
MutesAPI.deleteMute(targetUserId: targetUserId) { (response, error) in
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
 **targetUserId** | **String** | ミュート解除対象のユーザーID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMutes**
```swift
    open class func listMutes(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMuteListResponse?, _ error: Error?) -> Void)
```

ミュート一覧取得

認証済みユーザーがミュートしているユーザーの一覧をカーソルページネーションで取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20、最大 50） (optional)
let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// ミュート一覧取得
MutesAPI.listMutes(limit: limit, cursor: cursor) { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseMuteListResponse**](HackathonInternalHandlerSchemaResponseMuteListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

