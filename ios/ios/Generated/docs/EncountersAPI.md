# EncountersAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createEncounter**](EncountersAPI.md#createencounter) | **POST** /api/v1/encounters | すれ違い登録
[**getEncounterByID**](EncountersAPI.md#getencounterbyid) | **GET** /api/v1/encounters/{id} | すれ違い詳細取得
[**listEncounters**](EncountersAPI.md#listencounters) | **GET** /api/v1/encounters | すれ違い履歴一覧取得
[**markEncounterAsRead**](EncountersAPI.md#markencounterasread) | **PATCH** /api/v1/encounters/{id}/read | エンカウントを既読にする


# **createEncounter**
```swift
    open class func createEncounter(body: HackathonInternalHandlerSchemaRequestCreateEncounterRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseEncounterResponse?, _ error: Error?) -> Void)
```

すれ違い登録

BLE 検出トークンからすれ違いを登録する（同一ペア・短時間内は冪等）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreateEncounterRequest(occurredAt: "occurredAt_example", rssi: 123, targetBleToken: "targetBleToken_example", type: "type_example") // HackathonInternalHandlerSchemaRequestCreateEncounterRequest | すれ違い登録リクエスト

// すれ違い登録
EncountersAPI.createEncounter(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreateEncounterRequest**](HackathonInternalHandlerSchemaRequestCreateEncounterRequest.md) | すれ違い登録リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterResponse**](HackathonInternalHandlerSchemaResponseEncounterResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getEncounterByID**
```swift
    open class func getEncounterByID(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseEncounterDetailResponse?, _ error: Error?) -> Void)
```

すれ違い詳細取得

指定した ID のすれ違い詳細を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 対象すれ違い ID

// すれ違い詳細取得
EncountersAPI.getEncounterByID(id: id) { (response, error) in
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
 **id** | **String** | 対象すれ違い ID | 

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterDetailResponse**](HackathonInternalHandlerSchemaResponseEncounterDetailResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listEncounters**
```swift
    open class func listEncounters(limit: Int? = nil, cursor: String? = nil, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseEncounterListResponse?, _ error: Error?) -> Void)
```

すれ違い履歴一覧取得

認証ユーザーのすれ違い履歴を取得する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let limit = 987 // Int | 取得件数（省略時 20, 最大 50） (optional)
let cursor = "cursor_example" // String | 次ページ取得用カーソル (optional)

// すれ違い履歴一覧取得
EncountersAPI.listEncounters(limit: limit, cursor: cursor) { (response, error) in
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
 **limit** | **Int** | 取得件数（省略時 20, 最大 50） | [optional] 
 **cursor** | **String** | 次ページ取得用カーソル | [optional] 

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterListResponse**](HackathonInternalHandlerSchemaResponseEncounterListResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markEncounterAsRead**
```swift
    open class func markEncounterAsRead(id: String, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseEncounterReadResponse?, _ error: Error?) -> Void)
```

エンカウントを既読にする

指定したエンカウントを既読マークする（冪等）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 対象エンカウント ID

// エンカウントを既読にする
EncountersAPI.markEncounterAsRead(id: id) { (response, error) in
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
 **id** | **String** | 対象エンカウント ID | 

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterReadResponse**](HackathonInternalHandlerSchemaResponseEncounterReadResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

