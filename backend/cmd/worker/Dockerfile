FROM golang:1.25-bookworm

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
RUN go install github.com/air-verse/air@v1.64.5

COPY . .

CMD ["air", "-c", ".air.worker.toml"]
