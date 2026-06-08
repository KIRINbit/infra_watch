FROM golang:1.26-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o infrawatch ./cmd/infrawatch/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/infrawatch .
COPY --from=builder /app/templates ./templates
EXPOSE 8080
CMD ["./infrawatch"]
