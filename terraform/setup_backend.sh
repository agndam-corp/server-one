#!/bin/bash
# Script to create AWS resources for Terraform backend

# Variables
STATE_BUCKET="terraform-state-djasko-com"
LOCKS_TABLE="terraform-locks"
REGION="us-east-1"  # Change as needed

echo "Creating S3 bucket for Terraform state: $STATE_BUCKET"
# For us-east-1, we don't specify LocationConstraint
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket $STATE_BUCKET \
        --region $REGION
else
    aws s3api create-bucket \
        --bucket $STATE_BUCKET \
        --region $REGION \
        --create-bucket-configuration LocationConstraint=$REGION
fi

# Wait a bit for bucket creation to propagate
sleep 5

echo "Enabling versioning on the bucket..."
aws s3api put-bucket-versioning \
    --bucket $STATE_BUCKET \
    --versioning-configuration Status=Enabled

echo "Enabling server-side encryption on the bucket..."
aws s3api put-bucket-encryption \
    --bucket $STATE_BUCKET \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "Creating DynamoDB table for state locking: $LOCKS_TABLE"
aws dynamodb create-table \
    --table-name $LOCKS_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

echo "Waiting for DynamoDB table to be created..."
aws dynamodb wait table-exists --table-name $LOCKS_TABLE

echo "Backend resources created successfully!"
echo ""
echo "To use the new backend configuration:"
echo "1. Update the region in backend.tf if needed"
echo "2. Run: terraform init"
echo "3. When prompted, choose to migrate state to the new backend"
echo ""
echo "Note: If you have existing local state, Terraform will ask to migrate it to S3"