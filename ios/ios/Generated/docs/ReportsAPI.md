# ReportsAPI

All URIs are relative to *http://localhost:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createReport**](ReportsAPI.md#createreport) | **POST** /api/v1/reports | 通報作成


# **createReport**
```swift
    open class func createReport(body: HackathonInternalHandlerSchemaRequestCreateReportRequest, completion: @escaping (_ data: HackathonInternalHandlerSchemaResponseReportResponse?, _ error: Error?) -> Void)
```

通報作成

ユーザーまたはコメントを通報する。同じ対象への重複通報はエラーになる。

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let body = hackathon_internal_handler_schema_request.CreateReportRequest(reason: "reason_example", reportType: "reportType_example", reportedUserId: "reportedUserId_example", targetCommentId: "targetCommentId_example") // HackathonInternalHandlerSchemaRequestCreateReportRequest | 通報リクエスト

// 通報作成
ReportsAPI.createReport(body: body) { (response, error) in
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
 **body** | [**HackathonInternalHandlerSchemaRequestCreateReportRequest**](HackathonInternalHandlerSchemaRequestCreateReportRequest.md) | 通報リクエスト | 

### Return type

[**HackathonInternalHandlerSchemaResponseReportResponse**](HackathonInternalHandlerSchemaResponseReportResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

