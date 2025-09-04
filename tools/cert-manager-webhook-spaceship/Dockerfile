FROM golang:1.22-alpine as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# Cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o webhook main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
# Create app directory
WORKDIR /app
# Copy the binary
COPY --from=builder /workspace/webhook .
# Set proper permissions
RUN chmod +x ./webhook
# Create non-root user
RUN addgroup -S -g 1000 appgroup &&\
    adduser -S -u 1000 -G appgroup appuser
# Change ownership to the non-root user
RUN chown appuser:appgroup ./webhook
USER appuser
CMD ["./webhook"]