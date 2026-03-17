# MusicConnectionsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteMyMusicConnection**](MusicConnectionsAPI.md#deletemymusicconnection) | **DELETE** /api/v1/users/me/music-connections/{provider} | 音楽サービス連携解除
[**getMusicAuthorizeURL**](MusicConnectionsAPI.md#getmusicauthorizeurl) | **GET** /api/v1/music-connections/{provider}/authorize | 音楽サービス OAuth 認可 URL 取得
[**getMyMusicConnections**](MusicConnectionsAPI.md#getmymusicconnections) | **GET** /api/v1/users/me/music-connections | 音楽サービス連携一覧取得
[**handleMusicCallback**](MusicConnectionsAPI.md#handlemusiccallback) | **GET** /api/v1/music-connections/{provider}/callback | 音楽サービス OAuth コールバック


# **deleteMyMusicConnection**
```swift
    open class func deleteMyMusicConnection(provider: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

音楽サービス連携解除

指定プロバイダーの連携を解除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | spotify | apple_music

// 音楽サービス連携解除
MusicConnectionsAPI.deleteMyMusicConnection(provider: provider) { (response, error) in
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
 **provider** | **String** | spotify | apple_music | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMusicAuthorizeURL**
```swift
    open class func getMusicAuthorizeURL(provider: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse?, _ error: Error?) -> Void)
```

音楽サービス OAuth 認可 URL 取得

指定プロバイダーの OAuth 認可フローを開始し authorize_url を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | spotify | apple_music

// 音楽サービス OAuth 認可 URL 取得
MusicConnectionsAPI.getMusicAuthorizeURL(provider: provider) { (response, error) in
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
 **provider** | **String** | spotify | apple_music | 

### Return type

[**HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse**](HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyMusicConnections**
```swift
    open class func getMyMusicConnections(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMusicConnectionsResponse?, _ error: Error?) -> Void)
```

音楽サービス連携一覧取得

自分の音楽サービス連携一覧を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 音楽サービス連携一覧取得
MusicConnectionsAPI.getMyMusicConnections() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseMusicConnectionsResponse**](HackathonInternalHandlerSchemaResponseMusicConnectionsResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **handleMusicCallback**
```swift
    open class func handleMusicCallback(provider: String, code: String, state: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

音楽サービス OAuth コールバック

OAuth コールバックを処理し、認可コードをトークンに交換してアプリへリダイレクト

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | spotify | apple_music
let code = "code_example" // String | 認可コード
let state = "state_example" // String | CSRF state

// 音楽サービス OAuth コールバック
MusicConnectionsAPI.handleMusicCallback(provider: provider, code: code, state: state) { (response, error) in
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
 **provider** | **String** | spotify | apple_music | 
 **code** | **String** | 認可コード | 
 **state** | **String** | CSRF state | 

### Return type

Void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

