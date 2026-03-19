# PlaylistsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addPlaylistFavorite**](PlaylistsAPI.md#addplaylistfavorite) | **POST** /api/v1/playlists/{id}/favorites | プレイリストをお気に入り登録
[**addPlaylistTrack**](PlaylistsAPI.md#addplaylisttrack) | **POST** /api/v1/playlists/{id}/tracks | プレイリストにトラック追加
[**createPlaylist**](PlaylistsAPI.md#createplaylist) | **POST** /api/v1/playlists | プレイリスト作成
[**deletePlaylist**](PlaylistsAPI.md#deleteplaylist) | **DELETE** /api/v1/playlists/{id} | プレイリスト削除
[**getMyPlaylists**](PlaylistsAPI.md#getmyplaylists) | **GET** /api/v1/playlists/me | 自分のプレイリスト一覧取得
[**getPlaylist**](PlaylistsAPI.md#getplaylist) | **GET** /api/v1/playlists/{id} | プレイリスト取得
[**removePlaylistFavorite**](PlaylistsAPI.md#removeplaylistfavorite) | **DELETE** /api/v1/playlists/{id}/favorites | プレイリストのお気に入り解除
[**removePlaylistTrack**](PlaylistsAPI.md#removeplaylisttrack) | **DELETE** /api/v1/playlists/{id}/tracks/{trackId} | プレイリストからトラック削除
[**updatePlaylist**](PlaylistsAPI.md#updateplaylist) | **PATCH** /api/v1/playlists/{id} | プレイリスト更新


# **addPlaylistFavorite**
```swift
    open class func addPlaylistFavorite(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プレイリストをお気に入り登録

指定したプレイリストをお気に入りに追加する（公開プレイリストのみ、または所有者）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID

// プレイリストをお気に入り登録
PlaylistsAPI.addPlaylistFavorite(id: id) { (response, error) in
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
 **id** | **String** | プレイリストID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addPlaylistTrack**
```swift
    open class func addPlaylistTrack(id: String, body: HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プレイリストにトラック追加

プレイリストにトラックを追加する（所有者のみ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID
let body = hackathon_internal_handler_schema_request.AddPlaylistTrackRequest(trackId: "trackId_example") // HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest | トラック追加リクエスト

// プレイリストにトラック追加
PlaylistsAPI.addPlaylistTrack(id: id, body: body) { (response, error) in
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
 **id** | **String** | プレイリストID | 
 **body** | [**HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest**](HackathonInternalHandlerSchemaRequestAddPlaylistTrackRequest.md) | トラック追加リクエスト | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPlaylist**
```swift
    open class func createPlaylist(body: HackathonInternalHandlerSchemaRequestCreatePlaylistRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePlaylistResponse?, _ error: Error?) -> Void)
```

プレイリスト作成

認証済みユーザーの新規プレイリストを作成する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreatePlaylistRequest(description: "description_example", isPublic: false, name: "name_example") // HackathonInternalHandlerSchemaRequestCreatePlaylistRequest | プレイリスト作成リクエスト

// プレイリスト作成
PlaylistsAPI.createPlaylist(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreatePlaylistRequest**](HackathonInternalHandlerSchemaRequestCreatePlaylistRequest.md) | プレイリスト作成リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePlaylist**
```swift
    open class func deletePlaylist(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プレイリスト削除

プレイリストを削除する（所有者のみ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID

// プレイリスト削除
PlaylistsAPI.deletePlaylist(id: id) { (response, error) in
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
 **id** | **String** | プレイリストID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyPlaylists**
```swift
    open class func getMyPlaylists(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePlaylistListResponse?, _ error: Error?) -> Void)
```

自分のプレイリスト一覧取得

認証済みユーザー自身のプレイリスト一覧を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 自分のプレイリスト一覧取得
PlaylistsAPI.getMyPlaylists() { (response, error) in
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
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistListResponse**](HackathonInternalHandlerSchemaResponsePlaylistListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPlaylist**
```swift
    open class func getPlaylist(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePlaylistResponse?, _ error: Error?) -> Void)
```

プレイリスト取得

指定したプレイリストをトラック情報付きで取得する（公開プレイリストは誰でも取得可能、非公開は所有者のみ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID

// プレイリスト取得
PlaylistsAPI.getPlaylist(id: id) { (response, error) in
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
 **id** | **String** | プレイリストID | 

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removePlaylistFavorite**
```swift
    open class func removePlaylistFavorite(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プレイリストのお気に入り解除

指定したプレイリストをお気に入りから削除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID

// プレイリストのお気に入り解除
PlaylistsAPI.removePlaylistFavorite(id: id) { (response, error) in
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
 **id** | **String** | プレイリストID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removePlaylistTrack**
```swift
    open class func removePlaylistTrack(id: String, trackId: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プレイリストからトラック削除

プレイリストからトラックを削除する（所有者のみ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID
let trackId = "trackId_example" // String | トラックID

// プレイリストからトラック削除
PlaylistsAPI.removePlaylistTrack(id: id, trackId: trackId) { (response, error) in
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
 **id** | **String** | プレイリストID | 
 **trackId** | **String** | トラックID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePlaylist**
```swift
    open class func updatePlaylist(id: String, body: HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePlaylistResponse?, _ error: Error?) -> Void)
```

プレイリスト更新

プレイリストの名前・説明・公開設定を更新する（所有者のみ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | プレイリストID
let body = hackathon_internal_handler_schema_request.UpdatePlaylistRequest(description: "description_example", isPublic: false, name: "name_example") // HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest | プレイリスト更新リクエスト

// プレイリスト更新
PlaylistsAPI.updatePlaylist(id: id, body: body) { (response, error) in
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
 **id** | **String** | プレイリストID | 
 **body** | [**HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest**](HackathonInternalHandlerSchemaRequestUpdatePlaylistRequest.md) | プレイリスト更新リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponsePlaylistResponse**](HackathonInternalHandlerSchemaResponsePlaylistResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

