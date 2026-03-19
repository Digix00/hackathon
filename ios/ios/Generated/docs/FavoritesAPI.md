# FavoritesAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addTrackFavorite**](FavoritesAPI.md#addtrackfavorite) | **POST** /api/v1/tracks/{id}/favorites | トラックをお気に入り登録
[**listPlaylistFavorites**](FavoritesAPI.md#listplaylistfavorites) | **GET** /api/v1/users/me/playlist-favorites | お気に入りプレイリスト一覧取得
[**listTrackFavorites**](FavoritesAPI.md#listtrackfavorites) | **GET** /api/v1/users/me/track-favorites | お気に入りトラック一覧取得
[**removeTrackFavorite**](FavoritesAPI.md#removetrackfavorite) | **DELETE** /api/v1/tracks/{id}/favorites | トラックのお気に入り解除


# **addTrackFavorite**
```swift
    open class func addTrackFavorite(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseTrackFavoriteResponse?, _ error: Error?) -> Void)
```

トラックをお気に入り登録

指定したトラックをお気に入りに追加する。既にお気に入り済みの場合はべき等に処理し 200 を返す。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | トラックID（例: spotify:track:123）

// トラックをお気に入り登録
FavoritesAPI.addTrackFavorite(id: id) { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseTrackFavoriteResponse**](HackathonInternalHandlerSchemaResponseTrackFavoriteResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPlaylistFavorites**
```swift
    open class func listPlaylistFavorites(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse?, _ error: Error?) -> Void)
```

お気に入りプレイリスト一覧取得

認証済みユーザーのお気に入りプレイリスト一覧をカーソルページネーションで取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20、最大 50） (optional)
let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// お気に入りプレイリスト一覧取得
FavoritesAPI.listPlaylistFavorites(limit: limit, cursor: cursor) { (response, error) in
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

[**HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse**](HackathonInternalHandlerSchemaResponsePlaylistFavoriteListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTrackFavorites**
```swift
    open class func listTrackFavorites(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse?, _ error: Error?) -> Void)
```

お気に入りトラック一覧取得

認証済みユーザーのお気に入りトラック一覧をカーソルページネーションで取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20、最大 50） (optional)
let cursor = "cursor_example" // String | ページネーションカーソル (optional)

// お気に入りトラック一覧取得
FavoritesAPI.listTrackFavorites(limit: limit, cursor: cursor) { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse**](HackathonInternalHandlerSchemaResponseTrackFavoriteListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeTrackFavorite**
```swift
    open class func removeTrackFavorite(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

トラックのお気に入り解除

指定したトラックをお気に入りから削除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | トラックID（例: spotify:track:123）

// トラックのお気に入り解除
FavoritesAPI.removeTrackFavorite(id: id) { (response, error) in
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

