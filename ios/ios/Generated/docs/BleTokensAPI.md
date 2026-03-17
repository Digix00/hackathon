# BleTokensAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createBleToken**](BleTokensAPI.md#createbletoken) | **POST** /api/v1/ble-tokens | BLE トークン発行
[**getCurrentBleToken**](BleTokensAPI.md#getcurrentbletoken) | **GET** /api/v1/ble-tokens/current | 有効な BLE トークン取得
[**getUserByBleToken**](BleTokensAPI.md#getuserbybletoken) | **GET** /api/v1/ble-tokens/{token}/user | BLE トークンからユーザー情報取得


# **createBleToken**
```swift
    open class func createBleToken(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseBleTokenResponse?, _ error: Error?) -> Void)
```

BLE トークン発行

現在ログインしているユーザーの新規 BLE トークンを発行する（24時間有効）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// BLE トークン発行
BleTokensAPI.createBleToken() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseBleTokenResponse**](HackathonInternalHandlerSchemaResponseBleTokenResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCurrentBleToken**
```swift
    open class func getCurrentBleToken(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseBleTokenResponse?, _ error: Error?) -> Void)
```

有効な BLE トークン取得

現在ログインしているユーザーの有効な最新の BLE トークンを取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 有効な BLE トークン取得
BleTokensAPI.getCurrentBleToken() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseBleTokenResponse**](HackathonInternalHandlerSchemaResponseBleTokenResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserByBleToken**
```swift
    open class func getUserByBleToken(token: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseBleTokenUserResponse?, _ error: Error?) -> Void)
```

BLE トークンからユーザー情報取得

指定した BLE トークンに紐づくユーザーの公開プロフィールを取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let token = "token_example" // String | 対象の BLE トークン

// BLE トークンからユーザー情報取得
BleTokensAPI.getUserByBleToken(token: token) { (response, error) in
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
 **token** | **String** | 対象の BLE トークン | 

### Return type

[**HackathonInternalHandlerSchemaResponseBleTokenUserResponse**](HackathonInternalHandlerSchemaResponseBleTokenUserResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

