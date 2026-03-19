# LyricsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getChainDetail**](LyricsAPI.md#getchaindetail) | **GET** /api/v1/lyrics/chains/{chain_id} | チェーン詳細取得
[**submitLyric**](LyricsAPI.md#submitlyric) | **POST** /api/v1/lyrics | 歌詞投稿


# **getChainDetail**
```swift
    open class func getChainDetail(chainId: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseChainDetailResponse?, _ error: Error?) -> Void)
```

チェーン詳細取得

チェーンの詳細と参加者の歌詞一覧、生成楽曲を取得する。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let chainId = "chainId_example" // String | チェーンID

// チェーン詳細取得
LyricsAPI.getChainDetail(chainId: chainId) { (response, error) in
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
 **chainId** | **String** | チェーンID | 

### Return type

[**HackathonInternalHandlerSchemaResponseChainDetailResponse**](HackathonInternalHandlerSchemaResponseChainDetailResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitLyric**
```swift
    open class func submitLyric(body: HackathonInternalHandlerSchemaRequestSubmitLyricRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseSubmitLyricResponse?, _ error: Error?) -> Void)
```

歌詞投稿

すれ違い成立時に歌詞を投稿し、LyricChainに追加する。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.SubmitLyricRequest(content: "content_example", encounterId: "encounterId_example") // HackathonInternalHandlerSchemaRequestSubmitLyricRequest | 歌詞投稿リクエスト

// 歌詞投稿
LyricsAPI.submitLyric(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestSubmitLyricRequest**](HackathonInternalHandlerSchemaRequestSubmitLyricRequest.md) | 歌詞投稿リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseSubmitLyricResponse**](HackathonInternalHandlerSchemaResponseSubmitLyricResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

