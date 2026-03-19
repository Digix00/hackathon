package main

import (
	"fmt"
	"log"
	"net/url"
	"os"

	"hackathon/internal/infra/rdb"
)

func main() {
	dsn := buildDSN()
	db, err := rdb.Open(dsn, "production")
	if err != nil {
		log.Fatalf("db open failed: %v", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("db get failed: %v", err)
	}
	defer sqlDB.Close() //nolint:errcheck

	if err := rdb.Migrate(db); err != nil {
		log.Fatalf("migrate failed: %v", err)
	}
	log.Println("migration completed")
}

func buildDSN() string {
	user := mustEnv("DB_USER")
	password := mustEnv("DB_PASSWORD")
	name := mustEnv("DB_NAME")
	connName := mustEnv("DB_CONNECTION_NAME")
	return fmt.Sprintf(
		"postgres://%s@/%s?host=/cloudsql/%s",
		url.UserPassword(user, password).String(),
		url.PathEscape(name),
		connName,
	)
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env var %s is not set", key)
	}
	return v
}
