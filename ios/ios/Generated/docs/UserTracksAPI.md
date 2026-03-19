# UserTracksAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addUserTrack**](UserTracksAPI.md#addusertrack) | **POST** /api/v1/users/me/tracks | マイトラックに楽曲追加
[**deleteUserTrack**](UserTracksAPI.md#deleteusertrack) | **DELETE** /api/v1/users/me/tracks/{id} | マイトラックから楽曲削除
[**listUserTracks**](UserTracksAPI.md#listusertracks) | **GET** /api/v1/users/me/tracks | マイトラック一覧取得


# **addUserTrack**
```swift
    open class func addUserTrack(body: HackathonInternalHandlerSchemaRequestAddUserTrackRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseUserTrackResponse?, _ error: Error?) -> Void)
```

マイトラックに楽曲追加

認証済みユーザーのマイトラックに楽曲を追加する。既に登録済みの場合は 200 を返す。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.AddUserTrackRequest(trackId: "trackId_example") // HackathonInternalHandlerSchemaRequestAddUserTrackRequest | トラック追加リクエスト

// マイトラックに楽曲追加
UserTracksAPI.addUserTrack(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestAddUserTrackRequest**](HackathonInternalHandlerSchemaRequestAddUserTrackRequest.md) | トラック追加リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseUserTrackResponse**](HackathonInternalHandlerSchemaResponseUserTrackResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteUserTrack**
```swift
    open class func deleteUserTrack(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

マイトラックから楽曲削除

認証済みユーザーのマイトラックから楽曲を削除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | トラックID（例: spotify:track:123）

// マイトラックから楽曲削除
UserTracksAPI.deleteUserTrack(id: id) { (response, error) in
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
 **id** | **String** | トラックID（例: spotify:track:123） | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUserTracks**
```swift
    open class func listUserTracks(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseUserTrackListResponse?, _ error: Error?) -> Void)
```

マイトラック一覧取得

認証済みユーザーのマイトラック一覧をカーソルページネーションで取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20、最大 50） (optional)
let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// マイトラック一覧取得
UserTracksAPI.listUserTracks(limit: limit, cursor: cursor) { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseUserTrackListResponse**](HackathonInternalHandlerSchemaResponseUserTrackListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

