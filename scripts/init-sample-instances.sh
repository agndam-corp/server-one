#!/bin/bash

# Script to initialize sample AWS instances in the database

set -e  # Exit on any error

echo "Initializing sample AWS instances..."
DB_PASSWORD="asdasd"

# Check if DB_PASSWORD is set
if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is required"
    echo "Please set it and run this script again"
    exit 1
fi

# Navigate to the script directory
cd "$(dirname "$0")"

# Run the Go program to initialize sample instances
echo "Running initialization program..."
go run ../scripts/init-sample-instances.go

echo "Sample instances initialization completed successfully!"