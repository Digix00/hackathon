# HealthAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthz**](HealthAPI.md#healthz) | **GET** /healthz | ヘルスチェック
[**healthzPostgres**](HealthAPI.md#healthzpostgres) | **GET** /healthz/postgres | PostgreSQL ヘルスチェック


# **healthz**
```swift
    open class func healthz(completion: @escaping (_ data: [String: String]?, _ error: Error?) -> Void)
```

ヘルスチェック

サーバーが起動しているか確認する

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// ヘルスチェック
HealthAPI.healthz() { (response, error) in
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

**[String: String]**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthzPostgres**
```swift
    open class func healthzPostgres(completion: @escaping (_ data: [String: String]?, _ error: Error?) -> Void)
```

PostgreSQL ヘルスチェック

PostgreSQL への接続を確認する（タイムアウト 5s）

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// PostgreSQL ヘルスチェック
HealthAPI.healthzPostgres() { (response, error) in
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

**[String: String]**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

