package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	"hackathon/internal/infra/rdb"
)

func main() {
	targetUserID := mustEnv("SEED_TARGET_USER_ID")
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

	otherUserID := os.Getenv("SEED_OTHER_USER_ID")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if err := rdb.SeedProd(db, targetUserID); err != nil {
			log.Printf("seed failed: %v", err)
			http.Error(w, "seed failed", http.StatusInternalServerError)
			return
		}
		log.Printf("seed completed for user %s", targetUserID)

		if otherUserID != "" {
			if err := rdb.SeedProdCrossEncounter(db, targetUserID, otherUserID); err != nil {
				log.Printf("cross encounter seed failed: %v", err)
				http.Error(w, "cross encounter seed failed", http.StatusInternalServerError)
				return
			}
			log.Printf("cross encounter seed completed between %s and %s", targetUserID, otherUserID)
		}

		w.WriteHeader(http.StatusOK)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("listening on :%s (target user: %s)", port, targetUserID)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("server failed: %v", err)
	}
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
