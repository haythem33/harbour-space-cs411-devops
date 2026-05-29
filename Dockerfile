FROM golang:1.24@sha256:247fffb7158d7a68ad951dfdda7bf8af07ff4078d16abeb05bd3184effcad359 AS builder
WORKDIR /app
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Stage 2: Final Minimal Runtime Environment
FROM gcr.io/distroless/static-debian12:debug@sha256:7985579713fb1171e707d74659c67af3605642d1c9db305304c2998a99032615
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 4444
HEALTHCHECK --interval=10s --timeout=2s \
  CMD ["/busybox/wget", "-qO-", "http://localhost:4444/"] || exit 1
CMD ["/app/main"]
