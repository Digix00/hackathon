# SongsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**likeSong**](SongsAPI.md#likesong) | **POST** /api/v1/songs/{id}/likes | 楽曲にいいね
[**listMySongs**](SongsAPI.md#listmysongs) | **GET** /api/v1/users/me/songs | 自分が参加した楽曲一覧
[**unlikeSong**](SongsAPI.md#unlikesong) | **DELETE** /api/v1/songs/{id}/likes | 楽曲のいいねを取り消す


# **likeSong**
```swift
    open class func likeSong(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseLikeSongResponse?, _ error: Error?) -> Void)
```

楽曲にいいね

指定した楽曲にいいねする。すでにいいね済みの場合はエラー。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 楽曲ID

// 楽曲にいいね
SongsAPI.likeSong(id: id) { (response, error) in
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
 **id** | **String** | 楽曲ID | 

### Return type

[**HackathonInternalHandlerSchemaResponseLikeSongResponse**](HackathonInternalHandlerSchemaResponseLikeSongResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMySongs**
```swift
    open class func listMySongs(cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseListUserSongsResponse?, _ error: Error?) -> Void)
```

自分が参加した楽曲一覧

自分がLyricChainに参加して生成された楽曲の一覧を返す。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// 自分が参加した楽曲一覧
SongsAPI.listMySongs(cursor: cursor) { (response, error) in
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
 **cursor** | **String** | ページネーションカーソル | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseListUserSongsResponse**](HackathonInternalHandlerSchemaResponseListUserSongsResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unlikeSong**
```swift
    open class func unlikeSong(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

楽曲のいいねを取り消す

指定した楽曲のいいねを取り消す。いいねが存在しない場合はエラー。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 楽曲ID

// 楽曲のいいねを取り消す
SongsAPI.unlikeSong(id: id) { (response, error) in
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
 **id** | **String** | 楽曲ID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

