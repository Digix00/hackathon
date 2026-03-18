package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
)

// TokenEncrypter はOAuthトークンをAES-256-GCMで暗号化/復号する。
// DBには base64(nonce || ciphertext) の形式で保存する。
type TokenEncrypter struct {
	key []byte
}

// NewTokenEncrypter は64文字の16進数キー文字列からTokenEncrypterを生成する。
// キーが不正な場合はエラーを返す。
func NewTokenEncrypter(hexKey string) (*TokenEncrypter, error) {
	key, err := hex.DecodeString(hexKey)
	if err != nil {
		return nil, fmt.Errorf("暗号鍵のデコードに失敗: %w", err)
	}
	if len(key) != 32 {
		return nil, fmt.Errorf("暗号鍵は32バイト(64文字の16進数)必要です。%dバイトが指定されました", len(key))
	}
	return &TokenEncrypter{key: key}, nil
}

// Encrypt は平文トークンを暗号化し、base64エンコードされた暗号文を返す。
func (e *TokenEncrypter) Encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(e.key)
	if err != nil {
		return "", fmt.Errorf("AES cipher生成失敗: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("GCM生成失敗: %w", err)
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("nonce生成失敗: %w", err)
	}
	// Seal(dst, nonce, plaintext, additionalData) → nonce+ciphertext を結合
	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt はbase64エンコードされた暗号文を復号し、平文を返す。
func (e *TokenEncrypter) Decrypt(encoded string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return "", fmt.Errorf("暗号文のbase64デコード失敗: %w", err)
	}
	block, err := aes.NewCipher(e.key)
	if err != nil {
		return "", fmt.Errorf("AES cipher生成失敗: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("GCM生成失敗: %w", err)
	}
	if len(data) < gcm.NonceSize() {
		return "", fmt.Errorf("暗号文が短すぎます")
	}
	nonce, ciphertextBytes := data[:gcm.NonceSize()], data[gcm.NonceSize():]
	plaintext, err := gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", fmt.Errorf("復号失敗: %w", err)
	}
	return string(plaintext), nil
}
