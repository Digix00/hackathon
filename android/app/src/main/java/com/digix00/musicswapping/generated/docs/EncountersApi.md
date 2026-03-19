# EncountersApi

All URIs are relative to *http://localhost:8000*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**createEncounter**](EncountersApi.md#createEncounter) | **POST** api/v1/encounters | すれ違い登録 |
| [**getEncounterByID**](EncountersApi.md#getEncounterByID) | **GET** api/v1/encounters/{id} | すれ違い詳細取得 |
| [**listEncounters**](EncountersApi.md#listEncounters) | **GET** api/v1/encounters | すれ違い履歴一覧取得 |
| [**markEncounterAsRead**](EncountersApi.md#markEncounterAsRead) | **PATCH** api/v1/encounters/{id}/read | エンカウントを既読にする |



すれ違い登録

BLE 検出トークンからすれ違いを登録する（同一ペア・短時間内は冪等）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(EncountersApi::class.java)
val body : HackathonInternalHandlerSchemaRequestCreateEncounterRequest =  // HackathonInternalHandlerSchemaRequestCreateEncounterRequest | すれ違い登録リクエスト

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseEncounterResponse = webService.createEncounter(body)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **body** | [**HackathonInternalHandlerSchemaRequestCreateEncounterRequest**](HackathonInternalHandlerSchemaRequestCreateEncounterRequest.md)| すれ違い登録リクエスト | |

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterResponse**](HackathonInternalHandlerSchemaResponseEncounterResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


すれ違い詳細取得

指定した ID のすれ違い詳細を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(EncountersApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 対象すれ違い ID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseEncounterDetailResponse = webService.getEncounterByID(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 対象すれ違い ID | |

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterDetailResponse**](HackathonInternalHandlerSchemaResponseEncounterDetailResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


すれ違い履歴一覧取得

認証ユーザーのすれ違い履歴を取得する

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(EncountersApi::class.java)
val limit : kotlin.Int = 56 // kotlin.Int | 取得件数（省略時 20, 最大 50）
val cursor : kotlin.String = cursor_example // kotlin.String | 次ページ取得用カーソル

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseEncounterListResponse = webService.listEncounters(limit, cursor)
}
```

### Parameters
| **limit** | **kotlin.Int**| 取得件数（省略時 20, 最大 50） | [optional] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **cursor** | **kotlin.String**| 次ページ取得用カーソル | [optional] |

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterListResponse**](HackathonInternalHandlerSchemaResponseEncounterListResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


エンカウントを既読にする

指定したエンカウントを既読マークする（冪等）

### Example
```kotlin
// Import classes:
//import com.digix00.musicswapping.generated.*
//import com.digix00.musicswapping.generated.infrastructure.*
//import com.digix00.musicswapping.generated.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(EncountersApi::class.java)
val id : kotlin.String = id_example // kotlin.String | 対象エンカウント ID

launch(Dispatchers.IO) {
    val result : HackathonInternalHandlerSchemaResponseEncounterReadResponse = webService.markEncounterAsRead(id)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **id** | **kotlin.String**| 対象エンカウント ID | |

### Return type

[**HackathonInternalHandlerSchemaResponseEncounterReadResponse**](HackathonInternalHandlerSchemaResponseEncounterReadResponse.md)

### Authorization



### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

