# SharedTrackAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteSharedTrack**](SharedTrackAPI.md#deletesharedtrack) | **DELETE** /api/v1/users/me/shared-track | シェア中の楽曲解除
[**getSharedTrack**](SharedTrackAPI.md#getsharedtrack) | **GET** /api/v1/users/me/shared-track | シェア中の楽曲取得
[**upsertSharedTrack**](SharedTrackAPI.md#upsertsharedtrack) | **PUT** /api/v1/users/me/shared-track | シェア中の楽曲設定・更新


# **deleteSharedTrack**
```swift
    open class func deleteSharedTrack(completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

シェア中の楽曲解除

認証済みユーザーのシェア中の楽曲を解除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// シェア中の楽曲解除
SharedTrackAPI.deleteSharedTrack() { (response, error) in
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

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSharedTrack**
```swift
    open class func getSharedTrack(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseSharedTrackResponse?, _ error: Error?) -> Void)
```

シェア中の楽曲取得

認証済みユーザーが現在シェア中の楽曲を取得する。未設定の場合は shared_track: null を返す。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// シェア中の楽曲取得
SharedTrackAPI.getSharedTrack() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseSharedTrackResponse**](HackathonInternalHandlerSchemaResponseSharedTrackResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsertSharedTrack**
```swift
    open class func upsertSharedTrack(body: HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseSharedTrackResponse?, _ error: Error?) -> Void)
```

シェア中の楽曲設定・更新

認証済みユーザーのシェア中の楽曲を設定または更新する。初回設定時は 201、更新時は 200。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.UpsertSharedTrackRequest(trackId: "trackId_example") // HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest | シェアトラック設定リクエスト

// シェア中の楽曲設定・更新
SharedTrackAPI.upsertSharedTrack(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest**](HackathonInternalHandlerSchemaRequestUpsertSharedTrackRequest.md) | シェアトラック設定リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseSharedTrackResponse**](HackathonInternalHandlerSchemaResponseSharedTrackResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

