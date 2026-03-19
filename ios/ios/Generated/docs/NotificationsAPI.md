# NotificationsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listNotifications**](NotificationsAPI.md#listnotifications) | **GET** /api/v1/users/me/notifications | 通知一覧取得
[**markNotificationAsRead**](NotificationsAPI.md#marknotificationasread) | **PATCH** /api/v1/users/me/notifications/{id}/read | 通知を既読にする


# **listNotifications**
```swift
    open class func listNotifications(limit: Int? = nil, offset: Int? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseNotificationListResponse?, _ error: Error?) -> Void)
```

通知一覧取得

現在ログインしているユーザーの通知一覧を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（デフォルト: 20, 最大: 100） (optional)
let offset = 987 // Int | オフセット（デフォルト: 0） (optional)

// 通知一覧取得
NotificationsAPI.listNotifications(limit: limit, offset: offset) { (response, error) in
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
 **limit** | **Int** | 取得件数（デフォルト: 20, 最大: 100） | [optional] 
 **offset** | **Int** | オフセット（デフォルト: 0） | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseNotificationListResponse**](HackathonInternalHandlerSchemaResponseNotificationListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markNotificationAsRead**
```swift
    open class func markNotificationAsRead(id: String, completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

通知を既読にする

指定した通知を既読状態にする

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 通知 ID

// 通知を既読にする
NotificationsAPI.markNotificationAsRead(id: id) { (response, error) in
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
 **id** | **String** | 通知 ID | 

### Return type

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

