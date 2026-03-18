# TracksAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getTrack**](TracksAPI.md#gettrack) | **GET** /api/v1/tracks/{id} | 楽曲詳細取得
[**searchTracks**](TracksAPI.md#searchtracks) | **GET** /api/v1/tracks/search | 楽曲検索


# **getTrack**
```swift
    open class func getTrack(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseTrackResponse?, _ error: Error?) -> Void)
```

楽曲詳細取得

連携済み音楽アカウント経由でトラック詳細を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | track id

// 楽曲詳細取得
TracksAPI.getTrack(id: id) { (response, error) in
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
 **id** | **String** | track id | 

### Return type

[**HackathonInternalHandlerSchemaResponseTrackResponse**](HackathonInternalHandlerSchemaResponseTrackResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchTracks**
```swift
    open class func searchTracks(q: String, limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseTrackSearchResponse?, _ error: Error?) -> Void)
```

楽曲検索

連携済み Spotify アカウントを使ってトラック検索する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let q = "q_example" // String | query
let limit = 987 // Int | limit (max 50) (optional)
let cursor = "cursor_example" // String | opaque cursor (optional)

// 楽曲検索
TracksAPI.searchTracks(q: q, limit: limit, cursor: cursor) { (response, error) in
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
 **q** | **String** | query | 
 **limit** | **Int** | limit (max 50) | [optional] 
 **cursor** | **String** | opaque cursor | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseTrackSearchResponse**](HackathonInternalHandlerSchemaResponseTrackSearchResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

