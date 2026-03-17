# UsersAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createUser**](UsersAPI.md#createuser) | **POST** /api/v1/users | ユーザー作成
[**deleteMe**](UsersAPI.md#deleteme) | **DELETE** /api/v1/users/me | 自分のアカウント削除
[**getMe**](UsersAPI.md#getme) | **GET** /api/v1/users/me | 自分のユーザー情報取得
[**getUserByID**](UsersAPI.md#getuserbyid) | **GET** /api/v1/users/{id} | 他ユーザーのプロフィール取得
[**patchMe**](UsersAPI.md#patchme) | **PATCH** /api/v1/users/me | 自分のプロフィール更新


# **createUser**
```swift
    open class func createUser(body: HackathonInternalHandlerSchemaRequestCreateUserRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseUserResponse?, _ error: Error?) -> Void)
```

ユーザー作成

Firebase 認証済みの新規ユーザーを登録する（初回ログイン時に一度だけ呼ぶ）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreateUserRequest(ageVisibility: "ageVisibility_example", avatarUrl: "avatarUrl_example", bio: "bio_example", birthdate: "birthdate_example", displayName: "displayName_example", prefectureId: "prefectureId_example", sex: "sex_example") // HackathonInternalHandlerSchemaRequestCreateUserRequest | ユーザー作成リクエスト

// ユーザー作成
UsersAPI.createUser(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreateUserRequest**](HackathonInternalHandlerSchemaRequestCreateUserRequest.md) | ユーザー作成リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMe**
```swift
    open class func deleteMe(completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

自分のアカウント削除

DB レコードと Firebase アカウントを削除する（Firebase 削除はベストエフォート）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 自分のアカウント削除
UsersAPI.deleteMe() { (response, error) in
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

Void (empty response body)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMe**
```swift
    open class func getMe(completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseUserResponse?, _ error: Error?) -> Void)
```

自分のユーザー情報取得

認証中のユーザー自身のプロフィールを返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// 自分のユーザー情報取得
UsersAPI.getMe() { (response, error) in
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

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserByID**
```swift
    open class func getUserByID(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponsePublicUserResponse?, _ error: Error?) -> Void)
```

他ユーザーのプロフィール取得

指定した ID の公開プロフィールを返す

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 対象ユーザー ID

// 他ユーザーのプロフィール取得
UsersAPI.getUserByID(id: id) { (response, error) in
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
 **id** | **String** | 対象ユーザー ID | 

### Return type

[**HackathonInternalHandlerSchemaResponsePublicUserResponse**](HackathonInternalHandlerSchemaResponsePublicUserResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patchMe**
```swift
    open class func patchMe(body: HackathonInternalHandlerSchemaRequestUpdateUserRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseUserResponse?, _ error: Error?) -> Void)
```

自分のプロフィール更新

指定したフィールドだけを部分更新する（null フィールドは変更しない）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.UpdateUserRequest(ageVisibility: "ageVisibility_example", avatarUrl: "avatarUrl_example", bio: "bio_example", birthdate: "birthdate_example", displayName: "displayName_example", prefectureId: "prefectureId_example", sex: "sex_example") // HackathonInternalHandlerSchemaRequestUpdateUserRequest | プロフィール更新リクエスト

// 自分のプロフィール更新
UsersAPI.patchMe(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestUpdateUserRequest**](HackathonInternalHandlerSchemaRequestUpdateUserRequest.md) | プロフィール更新リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseUserResponse**](HackathonInternalHandlerSchemaResponseUserResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

