# SettingsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMySettings**](SettingsAPI.md#getmysettings) | **GET** /api/v1/users/me/settings | 自分の設定取得
[**patchMySettings**](SettingsAPI.md#patchmysettings) | **PATCH** /api/v1/users/me/settings | 自分の設定更新


# **getMySettings**
```swift
    open class func getMySettings(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseSettingsResponse?, _ error: Error?) -> Void)
```

自分の設定取得

認証中のユーザーのアプリ設定を返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 自分の設定取得
SettingsAPI.getMySettings() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseSettingsResponse**](HackathonInternalHandlerSchemaResponseSettingsResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patchMySettings**
```swift
    open class func patchMySettings(body: HackathonInternalHandlerSchemaRequestUpdateSettingsRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseSettingsResponse?, _ error: Error?) -> Void)
```

自分の設定更新

指定したフィールドだけを部分更新する（null フィールドは変更しない）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.UpdateSettingsRequest(announcementNotificationEnabled: false, batchNotificationEnabled: false, bleEnabled: false, commentNotificationEnabled: false, detectionDistance: 123, encounterNotificationEnabled: false, likeNotificationEnabled: false, locationEnabled: false, notificationEnabled: false, notificationFrequency: "notificationFrequency_example", profileVisible: false, scheduleEnabled: false, scheduleEndTime: "scheduleEndTime_example", scheduleStartTime: "scheduleStartTime_example", themeMode: "themeMode_example", trackVisible: false) // HackathonInternalHandlerSchemaRequestUpdateSettingsRequest | 設定更新リクエスト

// 自分の設定更新
SettingsAPI.patchMySettings(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestUpdateSettingsRequest**](HackathonInternalHandlerSchemaRequestUpdateSettingsRequest.md) | 設定更新リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseSettingsResponse**](HackathonInternalHandlerSchemaResponseSettingsResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

