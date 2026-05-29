# Stage 1: Build Environment
FROM golang:1.24@sha256:d2d2bc1c84f7e60d7d2438a3836ae7d0c847f4888464e7ec9ba3a1339a1ee804 AS builder
WORKDIR /app
COPY main.go .
# FIX: Target the specific file instead of the directory
RUN CGO_ENABLED=0 GOOS=linux go build -o main main.go

# Stage 2: Final Minimal Runtime Environment
FROM gcr.io/distroless/static-debian12:debug@sha256:46fcf1fa44d251b0944ba4b98ef4bbd266e33034e46489dbf92f680ca4917451
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 4444
HEALTHCHECK --interval=10s --timeout=2s \
  CMD ["/busybox/wget", "-qO-", "http://localhost:4444/"] || exit 1
CMD ["/app/main"]
