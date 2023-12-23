# KCD CZ 2023 booth demo

* [x] Install ACM
* [x] Install Hypershift
* [x] Create two prod clusters in different regions, stage and dev cluster
* [x] Dev cluster should tests github PRs
* [x] Add global load balancer
* [x] Rollout latest repo changes to stage
* [x] Prod clusters use custom overlay
* [x] Store secrets in Vault
* [x] stage pipeline: push image to ghcr.io
* [x] Run MCE and ArgoCD on infra nodes

## Howto

* Run `create-s3-bucket`, enable ACL in the bucket manually
* Rename machines in `bootstrap/05-infra-machines.yaml` to match random MachineSet hash
* `oc apply -f bootstrap` until all objects are created
* Get unseal key and vault token via `oc -n vault logs -f vault-0 -c auto-initializer`
* Update vault token in `secrets/setup-vault.sh`
* Run `02-update-vault.sh` to fill in Vault
* Apply main configuration: `oc apply -f app-hub.yaml` until all objects are created
* Once `openshift-logging` is created create a new Vault secret for `external-log-forwarder` SA
* Once `acm` app syncs create Hypershift clusters `bash create-<env>.sh`
* Sync `spoke-clusters` and `applicationsets` apps, enable autosync

## Techonologies used

* ACM to control spoke clusters
* MCE to spin up spoke clusters
* HyperShift to run control plane on hub cluster
* ArgoCD to control manifests via gitops
* Tekton to build images and rollout manifests
* Cert manager to issue Lets Encrypt certificates
* Global LB to loadbalance load between regional clusters
* KEDA to autoscale hub ingress based on connections
* ArgoCD Vault plugin to sync secrets to clusters
* Helm/Kustomize to adjust deployment settings
* Openshift Virtualization to spin up stage cluster
* Openshift Logging to collect logs
* Thanos to have a long-term metrics storage
* Descheduler to spread pods across nodes
