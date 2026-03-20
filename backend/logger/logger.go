package logger

import (
	"context"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

type contextKey struct{}

// New はzapロガーを初期化する。
// production環境ではJSON形式のStructuredログを出力し、
// それ以外ではカラー付きコンソールログを出力する。
func New(env string) (*zap.Logger, error) {
	if env == "production" {
		return zap.NewProduction()
	}
	cfg := zap.NewDevelopmentConfig()
	cfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	return cfg.Build()
}

// Nop はテスト用の何も出力しないロガーを返す。
func Nop() *zap.Logger {
	return zap.NewNop()
}

// WithContext はロガーをContextに埋め込んで返す。
// ハンドラー→ユースケース間でロガーを伝播する際に使用する。
func WithContext(ctx context.Context, log *zap.Logger) context.Context {
	return context.WithValue(ctx, contextKey{}, log)
}

// FromContext はContextからロガーを取り出す。
// ロガーが埋め込まれていない場合は zap.NewNop() を返す（nilを返さない）。
func FromContext(ctx context.Context) *zap.Logger {
	if log, ok := ctx.Value(contextKey{}).(*zap.Logger); ok && log != nil {
		return log
	}
	return zap.NewNop()
}
