package main

import (
	"context"
	"database/sql"
	"net/http"
	"os"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	e.HideBanner = true
	e.Use(middleware.Recover())
	e.Use(middleware.RequestID())

	e.GET("/healthz", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})

	e.GET("/healthz/postgres", func(c echo.Context) error {
		dsn := os.Getenv("DATABASE_URL")
		if dsn == "" {
			return c.JSON(http.StatusInternalServerError, map[string]string{
				"status": "error",
				"error":  "DATABASE_URL is not set",
			})
		}

		ctx, cancel := context.WithTimeout(c.Request().Context(), 5*time.Second)
		defer cancel()

		db, err := sql.Open("pgx", dsn)
		if err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{
				"status": "error",
				"error":  err.Error(),
			})
		}
		defer db.Close()

		err = db.PingContext(ctx)
		if err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{
				"status": "error",
				"error":  err.Error(),
			})
		}

		var result int
		err = db.QueryRowContext(ctx, "SELECT 1").Scan(&result)
		if err != nil {
			return c.JSON(http.StatusServiceUnavailable, map[string]string{
				"status": "error",
				"error":  err.Error(),
			})
		}

		return c.JSON(http.StatusOK, map[string]interface{}{
			"status": "ok",
			"db":     "postgres",
			"result": result,
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8000"
	}

	e.Logger.Fatal(e.Start(":" + port))
}
