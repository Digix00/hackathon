package errs

import "fmt"

type Code string

const (
	CodeNotFound     Code = "NOT_FOUND"
	CodeUnauthorized Code = "UNAUTHORIZED"
	CodeForbidden    Code = "FORBIDDEN"
	CodeConflict     Code = "CONFLICT"
	CodeBadRequest   Code = "BAD_REQUEST"
	CodeInternal     Code = "INTERNAL"
)

// センチネル変数。errors.Is() の比較対象として使う。
// Message は空でよい（Code だけで同一性を判定するため）。
var (
	ErrNotFound     = &DomainError{Code: CodeNotFound}
	ErrUnauthorized = &DomainError{Code: CodeUnauthorized}
	ErrForbidden    = &DomainError{Code: CodeForbidden}
	ErrConflict     = &DomainError{Code: CodeConflict}
	ErrBadRequest   = &DomainError{Code: CodeBadRequest}
	ErrInternal     = &DomainError{Code: CodeInternal}
)

type DomainError struct {
	Code    Code
	Message string
}

// Error はログ出力時に Code を必ず含める。
// sentinel（Message=""）でも "[NOT_FOUND]" のように識別できる。
func (e *DomainError) Error() string {
	if e.Message == "" {
		return fmt.Sprintf("[%s]", e.Code)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

// Is は errors.Is() が呼び出すメソッド。
// Code だけで比較することで、Message が異なるエラーも同種として扱える。
//
//	err := errs.NotFound("user not found")
//	errors.Is(err, errs.ErrNotFound) // => true
func (e *DomainError) Is(target error) bool {
	t, ok := target.(*DomainError)
	if !ok {
		return false
	}
	return e.Code == t.Code
}

// コンストラクタ。呼び出し元は詳細メッセージを付けてエラーを生成する。
//
//	return errs.NotFound("user %s not found", id)

func NotFound(msg string) *DomainError {
	return &DomainError{Code: CodeNotFound, Message: msg}
}

func Unauthorized(msg string) *DomainError {
	return &DomainError{Code: CodeUnauthorized, Message: msg}
}

func Forbidden(msg string) *DomainError {
	return &DomainError{Code: CodeForbidden, Message: msg}
}

func Conflict(msg string) *DomainError {
	return &DomainError{Code: CodeConflict, Message: msg}
}

func BadRequest(msg string) *DomainError {
	return &DomainError{Code: CodeBadRequest, Message: msg}
}

func Internal(msg string) *DomainError {
	return &DomainError{Code: CodeInternal, Message: msg}
}
