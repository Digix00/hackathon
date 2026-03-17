# UsersApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createUser**](UsersApi.md#createUser) | **POST** api/v1/users | ユーザー作成 |
| [**deleteMe**](UsersApi.md#deleteMe) | **DELETE** api/v1/users/me | 自分のアカウント削除 |
| [**getMe**](UsersApi.md#getMe) | **GET** api/v1/users/me | 自分のユーザー情報取得 |
| [**getUserByID**](UsersApi.md#getUserByID) | **GET** api/v1/users/{id} | 他ユーザーのプロフィール取得 |
| [**patchMe**](UsersApi.md#patchMe) | **PATCH** api/v1/users/me | 自分のプロフィール更新 |



ユーザー作成

Firebase 認証済みの新規ユーザーを登録する（初回ログイン時に一度だけ呼ぶ）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UsersApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreateUserRequest =  // HackathonInternalHandlerSchemaRequestCreateUserRequest | ユーザー作成リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseUserResponse = webService.createUser(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateUserRequest**](HackathonInternalHandlerSchemaRequestCreateUserRequest.md)| ユーザー作成リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


自分のアカウント削除

DB レコードと Firebase アカウントを削除する（Firebase 削除はベストエフォート）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UsersApi::class.java)

launch(Dispatchers.IO) {
    webService.deleteMe()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

null (empty response body)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*


自分のユーザー情報取得

認証中のユーザー自身のプロフィールを返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UsersApi::class.java)

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseUserResponse = webService.getMe()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


他ユーザーのプロフィール取得

指定した ID の公開プロフィールを返す

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UsersApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 対象ユーザー ID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponsePublicUserResponse = webService.getUserByID(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 対象ユーザー ID | |

### Return type

[**HackathonInternalHandlerSchemaResponsePublicUserResponse**](HackathonInternalHandlerSchemaResponsePublicUserResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


自分のプロフィール更新

指定したフィールドだけを部分更新する（null フィールドは変更しない）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(UsersApi::class.java)
val body : HackathonInternalHandlerSchemaRequestUpdateUserRequest =  // HackathonInternalHandlerSchemaRequestUpdateUserRequest | プロフィール更新リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseUserResponse = webService.patchMe(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestUpdateUserRequest**](HackathonInternalHandlerSchemaRequestUpdateUserRequest.md)| プロフィール更新リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

