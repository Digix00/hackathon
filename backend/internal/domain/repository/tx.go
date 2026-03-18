package repository

import "context"

// Transactor はトランザクション境界を提供するインターフェース。
// fn の引数として渡される context にトランザクションが埋め込まれており、
// リポジトリの各メソッドはこの context を通じてトランザクションに参加する。
type Transactor interface {
	RunInTx(ctx context.Context, fn func(ctx context.Context) error) error
}
