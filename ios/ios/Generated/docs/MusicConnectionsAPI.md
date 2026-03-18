# MusicConnectionsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteMusicConnection**](MusicConnectionsAPI.md#deletemusicconnection) | **DELETE** /api/v1/users/me/music-connections/{provider} | 音楽連携を解除
[**getMusicAuthorizeURL**](MusicConnectionsAPI.md#getmusicauthorizeurl) | **GET** /api/v1/music-connections/{provider}/authorize | 音楽サービス連携の認可 URL を取得
[**handleMusicCallback**](MusicConnectionsAPI.md#handlemusiccallback) | **GET** /api/v1/music-connections/{provider}/callback | 音楽サービス連携のコールバック
[**listMusicConnections**](MusicConnectionsAPI.md#listmusicconnections) | **GET** /api/v1/users/me/music-connections | 自分の音楽連携一覧を取得


# **deleteMusicConnection**
```swift
    open class func deleteMusicConnection(provider: Provider_deleteMusicConnection, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

音楽連携を解除

指定 provider の音楽連携を解除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | provider

// 音楽連携を解除
MusicConnectionsAPI.deleteMusicConnection(provider: provider) { (response, error) in
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
 **provider** | **String** | provider | 

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
    open class func getMusicAuthorizeURL(provider: Provider_getMusicAuthorizeURL, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse?, _ error: Error?) -> Void)
```

音楽サービス連携の認可 URL を取得

Spotify / Apple Music の OAuth 認可開始 URL と state を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | provider

// 音楽サービス連携の認可 URL を取得
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
 **provider** | **String** | provider | 

### Return type

[**HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse**](HackathonInternalHandlerSchemaResponseMusicAuthorizeResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **handleMusicCallback**
```swift
    open class func handleMusicCallback(provider: Provider_handleMusicCallback, code: String, state: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

音楽サービス連携のコールバック

OAuth コールバックを処理し、アプリ deep link へリダイレクトする

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let provider = "provider_example" // String | provider
let code = "code_example" // String | authorization code
let state = "state_example" // String | signed state

// 音楽サービス連携のコールバック
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
 **provider** | **String** | provider | 
 **code** | **String** | authorization code | 
 **state** | **String** | signed state | 

### Return type

Void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMusicConnections**
```swift
    open class func listMusicConnections(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseMusicConnectionsResponse?, _ error: Error?) -> Void)
```

自分の音楽連携一覧を取得

連携済み Spotify / Apple Music アカウント一覧を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 自分の音楽連携一覧を取得
MusicConnectionsAPI.listMusicConnections() { (response, error) in
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

