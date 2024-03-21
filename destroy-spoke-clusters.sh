export AWS_CREDS=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer/.aws/credentials
export BASE_DOMAIN=devcluster.openshift.com
hcp destroy cluster aws \
    --name vrutkovs-prod-eu \
    --infra-id vrutkovs-prod-eu \
    --aws-creds $AWS_CREDS \
    --region eu-west-3 \
    --base-domain $BASE_DOMAIN

hcp destroy cluster aws \
    --name vrutkovs-prod-us \
    --infra-id vrutkovs-prod-us \
    --aws-creds $AWS_CREDS \
    --region us-west-2 \
    --base-domain $BASE_DOMAIN
