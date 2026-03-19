# NotificationsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**listNotifications**](NotificationsApi.md#listNotifications) | **GET** api/v1/users/me/notifications | 通知一覧取得 |
| [**markNotificationAsRead**](NotificationsApi.md#markNotificationAsRead) | **PATCH** api/v1/users/me/notifications/{id}/read | 通知を既読にする |



通知一覧取得

現在ログインしているユーザーの通知一覧を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(NotificationsApi::class.java)
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（デフォルト: 20, 最大: 100）
val offset : kotlin.Int = 56 // kotlin.Int | オフセット（デフォルト: 0）

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseNotificationListResponse = webService.listNotifications(limit, offset)
}
```

### Parameters
| **limit** | **kotlin.Int**| 取得件数（デフォルト: 20, 最大: 100） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **offset** | **kotlin.Int**| オフセット（デフォルト: 0） | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseNotificationListResponse**](HackathonInternalHandlerSchemaResponseNotificationListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


通知を既読にする

指定した通知を既読状態にする

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(NotificationsApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 通知 ID

launch(Dispatchers.IO) {
    webService.markNotificationAsRead(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 通知 ID | |

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

