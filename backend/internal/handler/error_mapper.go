package handler

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"

	domainerrs "hackathon/internal/domain/errs"
)

// @name ErrorBody
type errorBody struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details any    `json:"details" swaggertype:"object"`
}

// @name ErrorResponse
type errorResponse struct {
	Error errorBody `json:"error"`
}

// InstallHTTPErrorHandler はzapロガーを使用するカスタムHTTPエラーハンドラーをEchoに登録する。
// ハンドラーはDomainErrorとecho.HTTPErrorを統一されたエラーレスポンス形式に変換する。
// レスポンス書き込みに失敗した場合はzapでエラーを記録する。
func InstallHTTPErrorHandler(e *echo.Echo, log *zap.Logger) {
	e.HTTPErrorHandler = func(err error, c echo.Context) {
		if c.Response().Committed {
			return
		}

		status, body := mapError(err)
		if jsonErr := c.JSON(status, errorResponse{Error: body}); jsonErr != nil {
			log.Error("failed to write error response",
				zap.Error(jsonErr),
				zap.String("request_id", c.Response().Header().Get(echo.HeaderXRequestID)),
				zap.String("path", c.Request().URL.Path),
			)
		}
	}
}

func mapError(err error) (int, errorBody) {
	if err == nil {
		return http.StatusInternalServerError, errorBody{Code: "INTERNAL", Message: "unknown error", Details: nil}
	}

	var domainErr *domainerrs.DomainError
	if errors.As(err, &domainErr) {
		return domainErrorToHTTP(domainErr)
	}

	var httpErr *echo.HTTPError
	if errors.As(err, &httpErr) {
		return httpErrorToResponse(httpErr)
	}

	return http.StatusInternalServerError, errorBody{
		Code:    "INTERNAL",
		Message: "Internal server error",
		Details: nil,
	}
}

func domainErrorToHTTP(err *domainerrs.DomainError) (int, errorBody) {
	status := http.StatusInternalServerError
	switch err.Code {
	case domainerrs.CodeBadRequest:
		status = http.StatusBadRequest
	case domainerrs.CodeUnauthorized:
		status = http.StatusUnauthorized
	case domainerrs.CodeForbidden:
		status = http.StatusForbidden
	case domainerrs.CodeNotFound:
		status = http.StatusNotFound
	case domainerrs.CodeConflict:
		status = http.StatusConflict
	case domainerrs.CodeInternal:
		status = http.StatusInternalServerError
	case domainerrs.CodeTooMany:
		status = http.StatusTooManyRequests
	}

	message := err.Message
	if message == "" {
		message = http.StatusText(status)
	}

	return status, errorBody{
		Code:    string(err.Code),
		Message: message,
		Details: nil,
	}
}

func httpErrorToResponse(err *echo.HTTPError) (int, errorBody) {
	status := err.Code
	if status == 0 {
		status = http.StatusInternalServerError
	}

	if body, ok := parseExplicitErrorBody(err.Message); ok {
		return status, body
	}

	message := http.StatusText(status)
	switch value := err.Message.(type) {
	case string:
		if value != "" {
			message = value
		}
	case error:
		if value.Error() != "" {
			message = value.Error()
		}
	}

	return status, errorBody{
		Code:    defaultCodeByStatus(status),
		Message: message,
		Details: nil,
	}
}

func parseExplicitErrorBody(message any) (errorBody, bool) {
	bodyMap, ok := message.(map[string]any)
	if !ok {
		return errorBody{}, false
	}

	code, _ := bodyMap["code"].(string)
	msg, _ := bodyMap["message"].(string)
	if code == "" || msg == "" {
		return errorBody{}, false
	}

	return errorBody{
		Code:    code,
		Message: msg,
		Details: bodyMap["details"],
	}, true
}

func defaultCodeByStatus(status int) string {
	switch status {
	case http.StatusBadRequest:
		return "BAD_REQUEST"
	case http.StatusUnauthorized:
		return "UNAUTHORIZED"
	case http.StatusForbidden:
		return "FORBIDDEN"
	case http.StatusNotFound:
		return "NOT_FOUND"
	case http.StatusConflict:
		return "CONFLICT"
	default:
		if status >= 500 {
			return "INTERNAL"
		}
		return fmt.Sprintf("HTTP_%d", status)
	}
}
