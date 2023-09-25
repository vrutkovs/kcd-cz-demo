export AWS_CREDS=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer/.aws/credentials
export REGION=eu-west-3
export BASE_DOMAIN=devcluster.openshift.com
hypershift destroy cluster aws \
    --name vrutkovs-prod-eu \
    --infra-id vrutkovs-prod-eu \
    --aws-creds $AWS_CREDS \
    --region $REGION \
    --base-domain $BASE_DOMAIN

export REGION=us-west-2
hypershift destroy cluster aws \
    --name vrutkovs-prod-us \
    --infra-id vrutkovs-prod-us \
    --aws-creds $AWS_CREDS \
    --region $REGION \
    --base-domain $BASE_DOMAIN

export REGION=us-east-2
hypershift destroy cluster aws \
    --name vrutkovs-stage \
    --infra-id vrutkovs-stage \
    --aws-creds $AWS_CREDS \
    --region $REGION \
    --base-domain $BASE_DOMAIN

export REGION=us-east-2
hypershift destroy cluster aws \
    --name vrutkovs-dev \
    --infra-id vrutkovs-dev \
    --aws-creds $AWS_CREDS \
    --region $REGION \
    --base-domain $BASE_DOMAIN
