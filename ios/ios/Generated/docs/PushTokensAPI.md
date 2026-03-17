# PushTokensAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPushToken**](PushTokensAPI.md#createpushtoken) | **POST** /api/v1/users/me/push-tokens | プッシュトークン登録（upsert）
[**deletePushToken**](PushTokensAPI.md#deletepushtoken) | **DELETE** /api/v1/users/me/push-tokens/{id} | プッシュトークン削除
[**patchPushToken**](PushTokensAPI.md#patchpushtoken) | **PATCH** /api/v1/users/me/push-tokens/{id} | プッシュトークン更新


# **createPushToken**
```swift
    open class func createPushToken(body: HackathonInternalHandlerSchemaRequestCreatePushTokenRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseDeviceResponse?, _ error: Error?) -> Void)
```

プッシュトークン登録（upsert）

device_id が既存なら更新して 200、新規なら 201 を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreatePushTokenRequest(appVersion: "appVersion_example", deviceId: "deviceId_example", platform: "platform_example", pushToken: "pushToken_example") // HackathonInternalHandlerSchemaRequestCreatePushTokenRequest | プッシュトークン登録リクエスト

// プッシュトークン登録（upsert）
PushTokensAPI.createPushToken(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreatePushTokenRequest**](HackathonInternalHandlerSchemaRequestCreatePushTokenRequest.md) | プッシュトークン登録リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseDeviceResponse**](HackathonInternalHandlerSchemaResponseDeviceResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePushToken**
```swift
    open class func deletePushToken(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

プッシュトークン削除

指定デバイスのレコードを削除する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | デバイス ID

// プッシュトークン削除
PushTokensAPI.deletePushToken(id: id) { (response, error) in
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
 **id** | **String** | デバイス ID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patchPushToken**
```swift
    open class func patchPushToken(id: String, body: HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseDeviceResponse?, _ error: Error?) -> Void)
```

プッシュトークン更新

指定デバイスのトークン・有効フラグ・アプリバージョンを部分更新する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | デバイス ID
let body = hackathon_internal_handler_schema_request.UpdatePushTokenRequest(appVersion: "appVersion_example", enabled: false, pushToken: "pushToken_example") // HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest | プッシュトークン更新リクエスト

// プッシュトークン更新
PushTokensAPI.patchPushToken(id: id, body: body) { (response, error) in
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
 **id** | **String** | デバイス ID | 
 **body** | [**HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest**](HackathonInternalHandlerSchemaRequestUpdatePushTokenRequest.md) | プッシュトークン更新リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseDeviceResponse**](HackathonInternalHandlerSchemaResponseDeviceResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

