# ReportsApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createReport**](ReportsApi.md#createReport) | **POST** api/v1/reports | 通報作成 |



通報作成

ユーザーまたはコメントを通報する。同じ対象への重複通報はエラーになる。

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(ReportsApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreateReportRequest =  // HackathonInternalHandlerSchemaRequestCreateReportRequest | 通報リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseReportResponse = webService.createReport(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateReportRequest**](HackathonInternalHandlerSchemaRequestCreateReportRequest.md)| 通報リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseReportResponse**](HackathonInternalHandlerSchemaResponseReportResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

