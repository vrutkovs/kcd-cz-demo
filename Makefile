.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
HUB_VERSION="4.14.13"
BASE_DOMAIN=devcluster.openshift.com
CLUSTER=vrutkovs-demo

OKD_INSTALLER_PATH=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer
AWS_CREDS=${OKD_INSTALLER_PATH}/.aws/credentials
OC=oc --kubeconfig=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig

all: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: create-s3-bucket create-hub-cluster update-infra-machine-hash bootstrap roll-out-infra-machines wait-for-operators-to-be-stable fill-up-vault install-hub ## Start install from scratch

create-s3-bucket:  ## Create S3 bucket for AWS clusters auth
	podman exec -u 1000 -w $(shell pwd) -ti fedora-toolbox-39 bash 01-create-s3-bucket.sh

create-hub-cluster: ## Create hub cluster
	cd ${OKD_INSTALLER_PATH} && \
	make gcp \
		VERSION=4.14 \
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
	yq eval-all '. as $$item' /tmp/doc_0.yaml /tmp/doc_1.yaml /tmp/doc_2.yaml /tmp/doc_3.yaml /tmp/doc_4.yaml > ${YAML}
	git add ${YAML}
	git commit -m "Update infra hash to ${INFRA_HASH}"
	git push
update-infra-machine-hash: YAML="apps/hub-infra/02-infra-machines.yaml"

bootstrap:
	while true; do \
		${OC} apply -f bootstrap && break; \
		sleep 30; \
	done

roll-out-infra-machines:
	${OC} get machine -n openshift-machine-api -o name | grep worker-a | xargs ${OC} -n openshift-machine-api delete
	${OC} get machine -n openshift-machine-api -o name | grep worker-b | xargs ${OC} -n openshift-machine-api delete

wait-for-operators-to-be-stable:
	${OC} adm wait-for-stable-cluster --minimum-stable-period=1s --timeout=30m

fill-up-vault:
	KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig ./02-update-vault.sh

install-hub:
	${OC} apply -f app-hub.yaml

.PHONY: all $(MAKECMDGOALS)
