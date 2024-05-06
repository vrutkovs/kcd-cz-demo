.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
HUB_VERSION="4.15.12-x86_64"
BASE_DOMAIN=devcluster.openshift.com
CLUSTER=vrutkovs-demo

OKD_INSTALLER_PATH=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer
AWS_CREDS=${OKD_INSTALLER_PATH}/.aws/credentials
OC=oc --kubeconfig=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig

all: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: create-s3-bucket create-google-sa create-hub-cluster update-infra-machine-hash argocd-bootstrap roll-out-infra-machines fill-up-vault install-hub wait-for-operators-to-be-stable update-scaled-hash ## Start install from scratch

create-s3-bucket:  ## Create S3 bucket for AWS clusters auth
	podman exec -u 1000 -w $(shell pwd) -ti fedora-toolbox-39 bash 01-create-s3-bucket.sh

create-google-sa:
	podman exec -u 1000 -w $(shell pwd) -ti fedora-toolbox-39 bash 02-create-google-serviceaccount.sh

create-hub-cluster:
	cd ${OKD_INSTALLER_PATH} && \
	make gcp \
		VERSION=4.15 \
		TYPE=ocp \
		TEMPLATE=templates/gcp-large.j2.yaml \
		RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${HUB_VERSION}

destroy-hub-cluster: ## Destroy hub cluster
	cd ${OKD_INSTALLER_PATH} && \
	make destroy-gcp \
		VERSION=4.14 \
		TYPE=ocp

update-infra-machine-hash:
	$(eval INFRA_HASH := $(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
			oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].metadata.name}' | cut -d '-' -f 3))
	yq e "select(documentIndex == 0) | .metadata.name = \"${CLUSTER}-${INFRA_HASH}-worker-a\"" ${YAML} > /tmp/doc_0.yaml
	yq e "select(documentIndex == 1) | .metadata.name = \"${CLUSTER}-${INFRA_HASH}-worker-b\"" ${YAML} > /tmp/doc_1.yaml
	yq e "select(documentIndex == 2) | .spec.scaleTargetRef.name = \"${CLUSTER}-${INFRA_HASH}-worker-a\"" ${YAML} > /tmp/doc_2.yaml
	yq e "select(documentIndex == 3) | .spec.scaleTargetRef.name = \"${CLUSTER}-${INFRA_HASH}-worker-b\"" ${YAML} > /tmp/doc_3.yaml
	yq e "select(documentIndex == 4) | .spec.scaleTargetRef.name = \"${CLUSTER}-${INFRA_HASH}-worker-c\"" ${YAML} > /tmp/doc_4.yaml
	yq eval-all /tmp/doc_0.yaml /tmp/doc_1.yaml /tmp/doc_2.yaml /tmp/doc_3.yaml /tmp/doc_4.yaml > ${YAML}
	git add ${YAML}
	git commit -m "Update infra hash to ${INFRA_HASH}"
	git push
update-infra-machine-hash: YAML="apps/hub-infra/02-infra-machines.yaml"

update-scaled-hash:
	$(eval HASH := $(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
			oc -n openshift-ingress-operator get secrets -o name | grep "metrics-reader-token" | cut -d '-' -f 4))
	yq e ".spec.secretTargetRef[0].name = \"metrics-reader-token-${HASH}\"" -i ${YAML}
	yq e ".spec.secretTargetRef[1].name = \"metrics-reader-token-${HASH}\"" -i ${YAML}
	git add ${YAML}
	git commit -m "Update metrics token hash to ${INFRA_HASH}"
	git push
update-scaled-hash: YAML="apps/keda/05-scale-trigger.yaml"

argocd-bootstrap:
	while true; do \
		${OC} apply -f bootstrap && break; \
		sleep 30; \
	done

roll-out-infra-machines:
	${OC} -n openshift-machine-api get machine -o name | grep worker-a | xargs ${OC} -n openshift-machine-api delete
	${OC} -n openshift-machine-api get machine -o name | grep worker-b | xargs ${OC} -n openshift-machine-api delete
	${OC} -n openshift-machine-api scale machineset ${CLUSTER}-${INFRA_HASH}-worker-c --replicas=3

wait-for-operators-to-be-stable:
	${OC} adm wait-for-stable-cluster --minimum-stable-period=30s --timeout=30m

fill-up-vault:
	${OC} apply hub/app-vault.yaml
	${OC} -n vault wait pods/vault-0 --for=condition=Ready
	KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig ./02-update-vault.sh

install-hub:
	${OC} apply -f app-hub.yaml

create-prod-eu:
	env KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
	hcp create cluster aws \
			--name "vrutkovs-prod-eu" \
			--infra-id "vrutkovs-prod-eu" \
			--control-plane-availability-policy=SingleReplica \
			--infra-availability-policy=SingleReplica \
			--aws-creds "${OKD_INSTALLER_PATH}/.aws/credentials" \
			--pull-secret "${OKD_INSTALLER_PATH}/pull_secrets/pull_secret.json" \
			--region "eu-west-3" \
			--base-domain "${BASE_DOMAIN}" \
			--generate-ssh \
			--node-pool-replicas 1 \
			--namespace clusters \
			--etcd-storage-class ssd-csi \
			--release-image quay.io/openshift-release-dev/ocp-release:4.14.23-x86_64

destroy-prod-eu:
	env KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
	hcp destroy cluster aws \
    --name vrutkovs-prod-eu \
    --infra-id vrutkovs-prod-eu \
    --aws-creds "${OKD_INSTALLER_PATH}/.aws/credentials" \
    --region eu-west-3 \
		--base-domain "${BASE_DOMAIN}"

create-prod-us:
	env KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
	hcp create cluster aws \
			--name "vrutkovs-prod-us" \
			--control-plane-availability-policy=SingleReplica \
			--infra-availability-policy=SingleReplica \
			--infra-id "vrutkovs-prod-us" \
			--aws-creds "${OKD_INSTALLER_PATH}/.aws/credentials" \
			--pull-secret "${OKD_INSTALLER_PATH}/pull_secrets/pull_secret.json" \
			--region "us-west-2" \
			--base-domain "${BASE_DOMAIN}" \
			--generate-ssh \
			--node-pool-replicas 1 \
			--namespace clusters \
			--etcd-storage-class ssd-csi \
			--release-image quay.io/openshift-release-dev/ocp-release:4.14.23-x86_64

destroy-prod-us:
	env KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
	hcp destroy cluster aws \
    --name vrutkovs-prod-us \
    --infra-id vrutkovs-prod-us \
    --aws-creds "${OKD_INSTALLER_PATH}/.aws/credentials" \
    --region us-west-2 \
    --base-domain "${BASE_DOMAIN}"

create-spoke-clusters: create-prod-eu create-prod-us ## Create spoke clusters
destroy-spoke-clusters: destroy-prod-eu destroy-prod-us ## Destroy spoke clusters
destroy: destroy-spoke-clusters destroy-hub-cluster ## Destroy spoke and hub

.PHONY: all $(MAKECMDGOALS)
