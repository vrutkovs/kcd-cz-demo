export CLUSTER_NAME=vrutkovs-dev
export INFRA_ID=vrutkovs-dev
export AWS_CREDS=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer/.aws/credentials
export PULL_SECRET=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer/pull_secrets/pull_secret.json
export REGION=us-east-2
export BASE_DOMAIN=devcluster.openshift.com
hypershift create cluster aws \
	--name "${CLUSTER_NAME}" \
	--infra-id "${INFRA_ID}" \
	--aws-creds "${AWS_CREDS}" \
	--pull-secret "${PULL_SECRET}" \
	--region "${REGION}" \
	--base-domain "${BASE_DOMAIN}" \
	--generate-ssh \
	--node-pool-replicas 1 \
	--namespace clusters \
	--etcd-storage-class ssd-csi \
	--release-image quay.io/openshift-release-dev/ocp-release:4.12.16-x86_64
