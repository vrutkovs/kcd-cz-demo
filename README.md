# KCD CZ 2023 booth demo

* [x] Install ACM
* [x] Install Hypershift
* [x] Create two prod clusters in different regions, stage and dev cluster
* [x] Dev cluster should tests github PRs
* [x] Add global load balancer
* [x] Rollout latest repo changes to stage
* [ ] Rollout changes to production via Blue/Green

## Howto

* Run `create-s3-bucket`, enable ACL in the bucket
* `oc apply -f bootstrap` until all objects are created
* `oc apply -f secrets` to create AWS creds and OIDC secret
* `bash runme.sh` for each folder in `clusters` to create Hypershift clusters
* Update manifests to match new `HostedCluster`s
* Sync remaining apps
