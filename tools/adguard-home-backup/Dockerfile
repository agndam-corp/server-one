#ghcr.io/damianjaskolski95/adguard-home-backup:latest
FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    curl \
    git \
    jq

# Set entrypoint
ENTRYPOINT ["/bin/sh"]