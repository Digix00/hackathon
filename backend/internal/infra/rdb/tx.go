package rdb

import (
	"context"

	"gorm.io/gorm"

	"hackathon/internal/usecase/port"
)

type txKey struct{}

// dbFromCtx はコンテキストに埋め込まれたトランザクション用 *gorm.DB を返す。
// トランザクションがない場合は fallback を返す。
// リポジトリの各メソッドは r.db の代わりにこの関数を呼び出すことで、
// usecase 層から開始されたトランザクションに自動的に参加できる。
func dbFromCtx(ctx context.Context, fallback *gorm.DB) *gorm.DB {
	if tx, ok := ctx.Value(txKey{}).(*gorm.DB); ok {
		return tx
	}
	return fallback
}

type gormTransactor struct{ db *gorm.DB }

// NewTransactor は Transactor を生成する。
func NewTransactor(db *gorm.DB) port.Transactor {
	return &gormTransactor{db: db}
}

// RunInTx は PostgreSQL トランザクションを開始し、fn をトランザクション内で実行する。
// fn が non-nil エラーを返した場合はロールバック、nil を返した場合はコミットする。
// fn に渡される context には *gorm.DB が埋め込まれており、
// dbFromCtx を使うリポジトリ実装はこのトランザクションに自動参加する。
func (t *gormTransactor) RunInTx(ctx context.Context, fn func(ctx context.Context) error) error {
	return t.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(context.WithValue(ctx, txKey{}, tx))
	})
}
