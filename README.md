# KCD CZ 2023 booth demo

* [x] Install ACM
* [x] Install Hypershift
* [x] Create two prod clusters in different regions, stage and dev cluster
* [x] Dev cluster should tests github PRs
* [x] Add global load balancer
* [x] Rollout latest repo changes to stage
* [x] Prod clusters use custom overlay
* [x] Autoscale pods on production via KEDA
  * [ ] KEDA scaling may be broken?
* [x] Store secrets via External Secrets
* [ ] dev pipeline: go vet and other checks
* [ ] dev pipeline: comment in PR
* [x] stage pipeline: push image to ghcr.io
* [x] Rollout changes to production via Blue/Green
  * [ ] Deployment still has one replica?
* [x] Run MCE and ArgoCD on infra nodes
* [ ] Describe what these pieces do

## Howto

* Run `create-s3-bucket`, enable ACL in the bucket manually
* `oc apply -f bootstrap` until all objects are created
* Wait for `acm` app to sync
* `oc apply -f secrets/secret-store.yaml` to create secret store
* `bash runme.sh` for each folder in `clusters` to create Hypershift clusters
* Sync remaining apps

## Techonologies used

* ACM to control spoke clsuters
* MCE to spin up spoke clusters
* HyperShift to run control plane on hub cluster
* ArgoCD to control manifests via gitops
* Tekton to build images and rollout manifests
* Argo Rollouts to do canary deployment
* Cert manager to issue Lets Encrypt certificates
* Global LB to loadbalance load between regional clusters
* KEDA to autoscale replicas based on connections
* External Secrets to sync secrets to clusters
* Helm/Kustomize to adjust deployment settings
