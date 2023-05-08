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
* [ ] Store secrets via External Secrets
* [ ] dev pipeline: go vet and other checks
* [ ] dev pipeline: comment in PR
* [ ] stage pipeline: push image to ghcr.io
* [ ] Rollout changes to production via Blue/Green
* [ ] Add [Cost Management](https://github.com/rhthsa/openshift-demo/blob/main/acm-observability.md)

## Howto

* Run `create-s3-bucket`, enable ACL in the bucket manually
* `oc apply -f bootstrap` until all objects are created
* Wait for `acm` app to sync
* `oc apply -f secrets` to create AWS creds and OIDC secret
* `bash runme.sh` for each folder in `clusters` to create Hypershift clusters
* Sync remaining apps
