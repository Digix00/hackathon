# TracksAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getTrack**](TracksAPI.md#gettrack) | **GET** /api/v1/tracks/{id} | トラック詳細取得
[**searchTracks**](TracksAPI.md#searchtracks) | **GET** /api/v1/tracks/search | トラック検索


# **getTrack**
```swift
    open class func getTrack(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseTrackDetailResponse?, _ error: Error?) -> Void)
```

トラック詳細取得

指定トラックの詳細を返す（ID: <provider>:track:<external_id>）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | トラック ID（例: spotify:track:123）

// トラック詳細取得
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
 **id** | **String** | トラック ID（例: spotify:track:123） | 

### Return type

[**HackathonInternalHandlerSchemaResponseTrackDetailResponse**](HackathonInternalHandlerSchemaResponseTrackDetailResponse.md)

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

トラック検索

Spotify Web API にプロキシするトラック検索

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let q = "q_example" // String | 検索キーワード
let limit = 987 // Int | 件数（省略時20、最大50） (optional)
let cursor = "cursor_example" // String | 次ページカーソル (optional)

// トラック検索
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
 **q** | **String** | 検索キーワード | 
 **limit** | **Int** | 件数（省略時20、最大50） | [optional] 
 **cursor** | **String** | 次ページカーソル | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseTrackSearchResponse**](HackathonInternalHandlerSchemaResponseTrackSearchResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

