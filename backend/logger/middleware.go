package logger

import (
	"time"

	"github.com/labstack/echo/v4"
	"go.uber.org/zap"
)

// userIDContextKey は handler/middleware.ContextKeyUserID と同一の文字列。
// importサイクルを避けるため、定数として直接保持する。
const userIDContextKey = "user_id"

// RequestLogger はHTTPリクエスト/レスポンスを構造化ログとして記録するEchoミドルウェアを返す。
//
// 記録するフィールド:
//   - request_id: X-Request-Id ヘッダー（middleware.RequestID() との併用前提）
//   - method / path / status / latency / bytes_out
//   - query: クエリパラメータが存在する場合のみ
//   - user_id: Firebase認証済みリクエストの場合のみ
//   - error: ハンドラーがエラーを返した場合のみ
//
// ログレベルはステータスコードとエラー有無で自動選択する:
//
//	5xx またはハンドラーエラー → Error
//	4xx                       → Warn
//	それ以外                  → Info
func RequestLogger(log *zap.Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			start := time.Now()
			req := c.Request()

			err := next(c)

			res := c.Response()
			latency := time.Since(start)

			fields := []zap.Field{
				zap.String("request_id", res.Header().Get(echo.HeaderXRequestID)),
				zap.String("method", req.Method),
				zap.String("path", req.URL.Path),
				zap.Int("status", res.Status),
				zap.Duration("latency", latency),
				zap.Int64("bytes_out", res.Size),
			}

			if q := req.URL.RawQuery; q != "" {
				fields = append(fields, zap.String("query", q))
			}
			if userID, ok := c.Get(userIDContextKey).(string); ok && userID != "" {
				fields = append(fields, zap.String("user_id", userID))
			}
			if err != nil {
				fields = append(fields, zap.Error(err))
			}

			switch {
			case err != nil || res.Status >= 500:
				log.Error("request", fields...)
			case res.Status >= 400:
				log.Warn("request", fields...)
			default:
				log.Info("request", fields...)
			}

			return err
		}
	}
}
