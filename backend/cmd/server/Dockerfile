FROM golang:1.25-bookworm

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
RUN go install github.com/air-verse/air@v1.64.5

COPY . .

EXPOSE 8000
CMD ["air", "-c", ".air.toml"]
