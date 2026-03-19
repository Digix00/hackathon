# LocationsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**postLocation**](LocationsAPI.md#postlocation) | **POST** /api/v1/locations | 現在位置送信・エンカウント判定


# **postLocation**
```swift
    open class func postLocation(body: HackathonInternalHandlerSchemaRequestPostLocationRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseLocationResponse?, _ error: Error?) -> Void)
```

現在位置送信・エンカウント判定

現在位置をサーバーに送信し、近くにいるユーザーとのエンカウントを判定・作成する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.PostLocationRequest(accuracyM: 123, lat: 123, lng: 123, recordedAt: "recordedAt_example") // HackathonInternalHandlerSchemaRequestPostLocationRequest | 位置情報リクエスト

// 現在位置送信・エンカウント判定
LocationsAPI.postLocation(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestPostLocationRequest**](HackathonInternalHandlerSchemaRequestPostLocationRequest.md) | 位置情報リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseLocationResponse**](HackathonInternalHandlerSchemaResponseLocationResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

