# HealthApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**healthz**](HealthApi.md#healthz) | **GET** healthz | ヘルスチェック |
| [**healthzPostgres**](HealthApi.md#healthzPostgres) | **GET** healthz/postgres | PostgreSQL ヘルスチェック |



ヘルスチェック

サーバーが起動しているか確認する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(HealthApi::class.java)

launch(Dispatchers.IO) {
    val result : kotlin.collections.Map<kotlin.String, kotlin.String> = webService.healthz()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**kotlin.collections.Map&lt;kotlin.String, kotlin.String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


PostgreSQL ヘルスチェック

PostgreSQL への接続を確認する（タイムアウト 5s）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(HealthApi::class.java)

launch(Dispatchers.IO) {
    val result : kotlin.collections.Map<kotlin.String, kotlin.String> = webService.healthzPostgres()
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**kotlin.collections.Map&lt;kotlin.String, kotlin.String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

