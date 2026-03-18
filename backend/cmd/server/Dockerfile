FROM golang:1.25-bookworm

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
RUN go install github.com/air-verse/air@v1.64.5
RUN go install github.com/swaggo/swag/cmd/swag
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.64.5

COPY . .

EXPOSE 8000
CMD ["air", "-c", ".air.toml"]
