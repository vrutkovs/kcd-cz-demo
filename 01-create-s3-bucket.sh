#!/bin/bash
set -eux
sudo dnf install -y /usr/bin/aws

BUCKET_NAME=vrutkovs-hypershift-demo
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region us-east-1
aws s3api delete-public-access-block --bucket "${BUCKET_NAME}"
echo "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
        {
            \"Effect\": \"Allow\",
            \"Principal\": \"*\",
            \"Action\": \"s3:GetObject\",
            \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\"
        }
    ]
}" | envsubst > policy.json
aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy file://policy.json
rm -rf policy.json

BUCKET_NAME=vrutkovs-demo
aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration "BlockPublicPolicy=false" # 2
aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::'"${BUCKET_NAME}"'/*"
            ]
        }
    ]
}'
