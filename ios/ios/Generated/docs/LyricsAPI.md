# LyricsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getLyricChain**](LyricsAPI.md#getlyricchain) | **GET** /api/v1/lyrics/chains/{chain_id} | 歌詞チェーン詳細取得
[**postLyric**](LyricsAPI.md#postlyric) | **POST** /api/v1/lyrics | 歌詞投稿


# **getLyricChain**
```swift
    open class func getLyricChain(chainId: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseLyricChainDetailResponse?, _ error: Error?) -> Void)
```

歌詞チェーン詳細取得

チェーンの詳細と全歌詞エントリを返す。completed 時のみ song フィールドが含まれる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let chainId = "chainId_example" // String | チェーン ID

// 歌詞チェーン詳細取得
LyricsAPI.getLyricChain(chainId: chainId) { (response, error) in
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
 **chainId** | **String** | チェーン ID | 

### Return type

[**HackathonInternalHandlerSchemaResponseLyricChainDetailResponse**](HackathonInternalHandlerSchemaResponseLyricChainDetailResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **postLyric**
```swift
    open class func postLyric(body: HackathonInternalHandlerSchemaRequestPostLyricRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePostLyricResponse?, _ error: Error?) -> Void)
```

歌詞投稿

エンカウントをきっかけに歌詞チェーンへ1行を投稿する。チェーンが threshold に達すると楽曲生成ジョブが登録される。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.PostLyricRequest(content: "content_example", encounterId: "encounterId_example") // HackathonInternalHandlerSchemaRequestPostLyricRequest | 歌詞投稿リクエスト

// 歌詞投稿
LyricsAPI.postLyric(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestPostLyricRequest**](HackathonInternalHandlerSchemaRequestPostLyricRequest.md) | 歌詞投稿リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponsePostLyricResponse**](HackathonInternalHandlerSchemaResponsePostLyricResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

