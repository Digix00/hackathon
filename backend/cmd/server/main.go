package main

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"go.uber.org/zap"

	"hackathon/config"
	"hackathon/internal/infra/rdb"
	applogger "hackathon/logger"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic("config load failed: " + err.Error())
	}

	log, err := applogger.New(cfg.GoEnv)
	if err != nil {
		panic("logger init failed: " + err.Error())
	}
	defer log.Sync() //nolint:errcheck

	db, err := rdb.Open(cfg.DatabaseURL, cfg.GoEnv)
	if err != nil {
		log.Fatal("db open failed", zap.Error(err))
	}
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("db get sql.DB failed", zap.Error(err))
	}
	defer sqlDB.Close()

	if err := rdb.Migrate(db); err != nil {
		log.Fatal("db migrate failed", zap.Error(err))
	}
	log.Info("db migration completed")

	// Seed は development / test 環境のみ実行する（allowlist 方式）。
	// staging など未知の環境でも誤って実行されないようにするため != "production" ではなく明示的に指定。
	if cfg.GoEnv == "development" || cfg.GoEnv == "test" {
		if err := rdb.Seed(db); err != nil {
			log.Fatal("db seed failed", zap.Error(err))
		}
		log.Info("db seed completed")
	}

	e := echo.New()
	e.HideBanner = true
	e.Use(middleware.Recover())
	e.Use(middleware.RequestID())

	e.GET("/healthz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})

	e.GET("/healthz/postgres", func(c echo.Context) error {
		ctx, cancel := context.WithTimeout(c.Request().Context(), 5*time.Second)
		defer cancel()

		if err := sqlDB.PingContext(ctx); err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{
				"status": "error",
				"error":  err.Error(),
			})
		}

		return c.JSON(http.StatusOK, map[string]string{"status": "ok", "db": "postgres"})
	})

	log.Info("server starting", zap.String("port", cfg.Port))

	if err := e.Start(":" + cfg.Port); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal("server error", zap.Error(err))
	}
}
