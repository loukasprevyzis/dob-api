FROM golang:1.24-alpine AS builder


RUN apk add --no-cache git
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o dob-api ./cmd/server

FROM alpine:latest

RUN apk --no-cache add ca-certificates
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=builder /app/dob-api .

RUN chown appuser:appgroup dob-api
USER appuser

EXPOSE 8080
CMD ["./dob-api"]