.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
HUB_VERSION="4.15.14-x86_64"
BASE_DOMAIN=devcluster.openshift.com
CLUSTER=vrutkovs-demo

OKD_INSTALLER_PATH=/var/home/vrutkovs/src/github.com/vrutkovs/okd-installer
AWS_CREDS=${OKD_INSTALLER_PATH}/.aws/credentials
OC=oc --kubeconfig=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig

all: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: create-s3-bucket create-google-sa create-hub-cluster argocd-bootstrap fill-up-vault install-hub ## Start install from scratch

create-s3-bucket:  ## Create S3 bucket for AWS clusters auth
	podman exec -u 1000 -w $(shell pwd) -ti fedora-toolbox-39 bash 01-create-s3-bucket.sh

create-google-sa:
	podman exec -u 1000 -w $(shell pwd) -ti fedora-toolbox-39 bash 02-create-google-serviceaccount.sh

copy-machineset:
	$(eval MS_NAME := ${ROLE}-${LETTER})
	$(eval FILE_NAME := 99_openshift-cluster-api_${ROLE}-machineset-${INDEX}.yaml)
	cd ${OKD_INSTALLER_PATH}/clusters/vrutkovs-demo/openshift && \
		if [[ ${ROLE} != "worker" ]]; then cp -rvf 99_openshift-cluster-api_worker-machineset-${INDEX}.yaml ${FILE_NAME}; fi && \
		yq e ".metadata.name = \"${MS_NAME}\"" -i ${FILE_NAME} && \
		yq e ".spec.selector.matchLabels.\"machine.openshift.io/cluster-api-machineset\" = \"${MS_NAME}\"" -i ${FILE_NAME} && \
		yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machineset\" = \"${MS_NAME}\"" -i ${FILE_NAME} && \
		yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machine-role\" = \"${ROLE}\"" -i ${FILE_NAME} && \
		yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machine-type\" = \"${ROLE}\"" -i ${FILE_NAME} && \
		yq e ".spec.template.metadata.labels.\"node-role.kubernetes.io/${ROLE}\" = \"\"" -i ${FILE_NAME} && \
		yq e ".spec.template.metadata.labels.\"machine.openshift.io/cluster-api-machine-type\" = \"${ROLE}\"" -i ${FILE_NAME} && \
		yq e ".spec.template.spec.providerSpec.value.machineType = \"${MACHINE_TYPE}\"" -i ${FILE_NAME} && \
		yq e '.spec.template.spec.providerSpec.value.preemtible=true' -i ${FILE_NAME} && \
		if [[ ${ROLE} != "worker" ]]; then \
			yq e ".spec.replicas = 0" -i ${FILE_NAME} && \
			yq e ".spec.template.spec.taints[0].key = \"node-role.kubernetes.io/${ROLE}\"" -i ${FILE_NAME} && \
			yq e ".spec.template.spec.taints[0].effect = \"NoSchedule\"" -i ${FILE_NAME} && \
			yq e ".spec.template.spec.taints[0].value = \"reserved\"" -i ${FILE_NAME}; \
		fi

create-hub-cluster: gcp-createmanifests gcp-updatehashes gcp-createcluster

gcp-createmanifests:
	cd ${OKD_INSTALLER_PATH} && \
	make gcp-createmanifests \
		VERSION=4.15 \
		TYPE=ocp \
		TEMPLATE=templates/gcp-large.j2.yaml \
		RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${HUB_VERSION}

gcp-updatehashes:
	$(eval HASH := $(shell yq e ".metadata.name" ${OKD_INSTALLER_PATH}/clusters/vrutkovs-demo/openshift/99_openshift-cluster-api_worker-machineset-0.yaml | cut -d'-' -f3))
	echo "HASH=${HASH}"
	make copy-machineset INDEX=0 LETTER=a ROLE=infra HASH=${HASH} MACHINE_TYPE=n2-standard-8
	make copy-machineset INDEX=1 LETTER=b ROLE=infra HASH=${HASH} MACHINE_TYPE=n2-standard-8
	make copy-machineset INDEX=2 LETTER=c ROLE=infra HASH=${HASH} MACHINE_TYPE=n2-standard-8
	make copy-machineset INDEX=0 LETTER=a ROLE=virtualization HASH=${HASH} MACHINE_TYPE=n2-highmem-8
	make copy-machineset INDEX=1 LETTER=b ROLE=virtualization HASH=${HASH} MACHINE_TYPE=n2-highmem-8
	make copy-machineset INDEX=2 LETTER=c ROLE=virtualization HASH=${HASH} MACHINE_TYPE=n2-highmem-8
	make copy-machineset INDEX=0 LETTER=a ROLE=worker HASH=${HASH} MACHINE_TYPE=n2-standard-8
	make copy-machineset INDEX=1 LETTER=b ROLE=worker HASH=${HASH} MACHINE_TYPE=n2-standard-8
	make copy-machineset INDEX=2 LETTER=c ROLE=worker HASH=${HASH} MACHINE_TYPE=n2-standard-8

gcp-createcluster:
	cd ${OKD_INSTALLER_PATH} && \
	make gcp-createcluster \
		VERSION=4.15 \
		TYPE=ocp \
		TEMPLATE=templates/gcp-large.j2.yaml \
		RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:${HUB_VERSION}

destroy-hub-cluster: ## Destroy hub cluster
	cd ${OKD_INSTALLER_PATH} && \
	make destroy-gcp \
		VERSION=4.15 \
		TYPE=ocp

update-hashes:
	while true; do \
		if [[ "$(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
				oc -n openshift-ingress-operator get secrets -o name | grep "metrics-reader-token")" == "" ]]; then sleep 30; continue; fi && \
		make update-scaled-hash METRIC_HASH="$(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
				oc -n openshift-ingress-operator get secrets -o name | grep "metrics-reader-token" | cut -d '-' -f 4)"; \
		break; \
	done
	while true; do \
		if [[ "$(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
			oc -n grafana-operator get secrets -o name | grep "clusterreader-sa-token")" == "" ]]; then sleep 30; continue; fi && \
		make update-grafana-hash GRAFANA_HASH="$(shell KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
			oc -n grafana-operator get secrets -o name | grep "clusterreader-sa-token" | cut -d '-' -f 4)"; \
		break; \
	done

update-scaled-hash:
	yq e ".spec.secretTargetRef[0].name = \"metrics-reader-token-${METRIC_HASH}\"" -i ${YAML}
	yq e ".spec.secretTargetRef[1].name = \"metrics-reader-token-${METRIC_HASH}\"" -i ${YAML}
	git add ${YAML}
	git commit -m "Update metrics token hash to ${METRIC_HASH}"
	git push
update-scaled-hash: YAML="apps/keda/05-scale-trigger.yaml"

update-grafana-hash:
	yq e "select(documentIndex == 0) | .spec.valuesFrom[0].valueFrom.secretKeyRef.name = \"clusterreader-sa-token-${GRAFANA_HASH}\"" ${YAML} > /tmp/doc_0.yaml
	yq e "select(documentIndex == 1) | .spec.valuesFrom[0].valueFrom.secretKeyRef.name = \"clusterreader-sa-token-${GRAFANA_HASH}\"" ${YAML} > /tmp/doc_1.yaml
	yq e "select(documentIndex == 2) | .spec.valuesFrom[0].valueFrom.secretKeyRef.name = \"clusterreader-sa-token-${GRAFANA_HASH}\"" ${YAML} > /tmp/doc_2.yaml
	yq e "select(documentIndex == 3) | .spec.valuesFrom[0].valueFrom.secretKeyRef.name = \"clusterreader-sa-token-${GRAFANA_HASH}\"" ${YAML} > /tmp/doc_3.yaml
	yq eval-all /tmp/doc_0.yaml /tmp/doc_1.yaml /tmp/doc_2.yaml /tmp/doc_3.yaml > ${YAML}
	git add ${YAML}
	git commit -m "Update grafana sa token hash to ${GRAFANA_HASH}"
	git push
update-grafana-hash: YAML="apps/grafana/05-datasources.yaml"

argocd-bootstrap:
	while true; do \
		${OC} apply -f bootstrap && break; \
		sleep 30; \
	done

wait-for-operators-to-be-stable:
	${OC} adm wait-for-stable-cluster --minimum-stable-period=30s --timeout=30m

fill-up-vault:
	while true; do \
		${OC} apply -f hub/app-vault.yaml && ${OC} -n vault wait pods/vault-0 --for=condition=Initialized && break; \
		sleep 30; \
	done
	sleep 30
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
			--region "eu-central-1" \
			--base-domain "${BASE_DOMAIN}" \
			--generate-ssh \
			--node-pool-replicas 1 \
			--namespace clusters \
			--etcd-storage-class ssd-csi \
			--instance-type g5.4xlarge \
			--release-image quay.io/openshift-release-dev/ocp-release:4.14.23-x86_64

destroy-prod-eu:
	env KUBECONFIG=${OKD_INSTALLER_PATH}/clusters/${CLUSTER}/auth/kubeconfig \
	hcp destroy cluster aws \
    --name vrutkovs-prod-eu \
    --infra-id vrutkovs-prod-eu \
    --aws-creds "${OKD_INSTALLER_PATH}/.aws/credentials" \
    --region eu-central-1 \
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
			--instance-type g5.4xlarge \
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
