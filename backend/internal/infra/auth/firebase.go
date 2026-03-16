package auth

import (
	"context"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
)

// NewFirebaseAuthClient は Firebase Auth クライアントを初期化して返す。
//
// 認証情報の解決順序（Firebase SDK のデフォルト動作）:
//  1. GOOGLE_APPLICATION_CREDENTIALS 環境変数が指す JSON キーファイル
//  2. GCP 上で動作している場合はサービスアカウントのメタデータ
//
// エミュレータを使う場合は FIREBASE_AUTH_EMULATOR_HOST 環境変数を設定すると
// SDK が自動的に検出してエミュレータへ接続する。
func NewFirebaseAuthClient(ctx context.Context, projectID string) (*auth.Client, error) {
	cfg := &firebase.Config{}
	if projectID != "" {
		cfg.ProjectID = projectID
	}

	app, err := firebase.NewApp(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("auth.NewFirebaseAuthClient new app: %w", err)
	}

	client, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("auth.NewFirebaseAuthClient get auth: %w", err)
	}

	return client, nil
}
