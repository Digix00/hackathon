// @title           MusicSwapping API
// @version         1.0
// @description     MusicSwapping バックエンド API
// @host            localhost:8000
// @BasePath        /
// @securityDefinitions.apikey BearerAuth
// @in              header
// @name            Authorization
// @description     Firebase ID トークン。"Bearer <token>" の形式で渡す。
package main

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	echoSwagger "github.com/swaggo/echo-swagger"
	"go.uber.org/zap"

	"hackathon/config"
	_ "hackathon/docs"
	"hackathon/internal/handler"
	infraauth "hackathon/internal/infra/auth"
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

	authClient, err := infraauth.NewFirebaseAuthClient(context.Background(), cfg.FirebaseProjectID)
	if err != nil {
		log.Fatal("firebase auth client init failed", zap.Error(err))
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

	if cfg.GoEnv == "development" || cfg.GoEnv == "test" {
		e.GET("/swagger/*", echoSwagger.WrapHandler)
		log.Info("swagger UI enabled", zap.String("url", "http://localhost:"+cfg.Port+"/swagger/index.html"))
	}

	e.GET("/healthz", healthzHandler)
	e.GET("/healthz/postgres", healthzPostgresHandler(sqlDB))

	handler.RegisterRoutes(e, buildDependencies(db, authClient, cfg))

	log.Info("server starting", zap.String("port", cfg.Port))

	if err := e.Start(":" + cfg.Port); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal("server error", zap.Error(err))
	}
}

func healthzHandler(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}

func healthzPostgresHandler(sqlDB interface{ PingContext(context.Context) error }) echo.HandlerFunc {
	return func(c echo.Context) error {
		ctx, cancel := context.WithTimeout(c.Request().Context(), 5*time.Second)
		defer cancel()
		if err := sqlDB.PingContext(ctx); err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{"status": "error", "error": err.Error()})
		}
		return c.JSON(http.StatusOK, map[string]string{"status": "ok", "db": "postgres"})
	}
}
