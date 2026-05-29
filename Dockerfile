FROM golang:1.24@sha256:7b55da6324bbfcc71b31d0db217edeb39b8bc7da3068e47eb5cb03bb4b8b6038 AS builder
WORKDIR /app
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM gcr.io/distroless/static-debian12:debug@sha256:49c063b4b5e826b52787c8052cd712c9c7f1a396cd8427da97ed3e4c49fa53cd
WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 4444
HEALTHCHECK --interval=10s --timeout=2s \
CMD ["/busybox/wget", "-qO-", "http://localhost:4444/"] || exit 1
CMD ["/app/main"]
