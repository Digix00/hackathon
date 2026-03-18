package rdb

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

// isUniqueConstraintViolation checks if the error is a PostgreSQL unique constraint violation (code 23505).
func isUniqueConstraintViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}
	return false
}

// isForeignKeyViolation checks if the error is a PostgreSQL foreign key violation (code 23503).
func isForeignKeyViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23503"
	}
	return false
}
