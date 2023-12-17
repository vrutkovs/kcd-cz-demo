#!/bin/bash
set -eux
oc project vault
for file in $(ls secrets/); do
  oc exec -ti vault-0 -- sh -c "cat - > /tmp/${file}" < secrets/${file}
done
oc exec -ti vault-0 -- bash -c "chmod a+x /tmp/setup-vault.sh && bash /tmp/setup-vault.sh"
