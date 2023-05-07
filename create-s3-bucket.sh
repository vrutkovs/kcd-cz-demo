#!/bin/bash
set -eux
BUCKET_NAME=vrutkovs-hypershift-demo
aws s3api create-bucket --bucket $BUCKET_NAME
aws s3api delete-public-access-block --bucket $BUCKET_NAME
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
}" | envsubst > secrets/policy.json
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://secrets/policy.json
