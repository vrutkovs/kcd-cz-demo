#!/bin/bash
echo "Copying secrets"
oc project vault
for file in $(ls secrets/); do
  oc exec -ti vault-0 -- sh -c "cat - > /tmp/${file}" < secrets/${file}
done
echo "Updating vault"
oc exec -ti vault-0 -- bash <<EOF
set -eux
export VAULT_ADDR=https://localhost:8200
export VAULT_SKIP_VERIFY=true
export VAULT_CACERT=/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt

export INIT_RESPONSE=\$(vault operator init -format=json -key-shares 1 -key-threshold 1)
echo "\$INIT_RESPONSE"
export UNSEAL_KEY=\$(echo "\$INIT_RESPONSE" | /usr/local/libexec/vault/jq -r .unseal_keys_b64[0])
export VAULT_TOKEN=\$(echo "\$INIT_RESPONSE" | /usr/local/libexec/vault/jq -r .root_token)
echo "\$UNSEAL_KEY"
echo "\$VAULT_TOKEN"

vault operator unseal \$UNSEAL_KEY

vault auth enable kubernetes
vault write auth/kubernetes/config \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token \
  kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer=https://kubernetes.default.svc

vault secrets enable -path=secret/ -version=2 kv

vault policy write vault_plugin - << EOZ
path "secret/*" {
  capabilities = ["read"]
}
EOZ
vault write auth/kubernetes/role/vault_plugin \
    bound_service_account_names=vault-plugin \
    bound_service_account_namespaces=openshift-gitops \
    policies=vault_plugin \
    ttl=1h

vault kv put secret/aws-creds @/tmp/aws-creds.json
vault kv patch secret/aws-creds ssh-privatekey=@/tmp/ssh-private-key
vault kv patch secret/aws-creds ssh-publickey=@/tmp/ssh-public-key
vault kv patch secret/aws-creds pullSecret=@/tmp/pull-secret.json

vault kv put secret/github-token token=@/tmp/github-token
vault kv put secret/oidc @/tmp/oidc.json
vault kv patch secret/oidc credentials=@/tmp/aws-creds.conf

vault kv put secret/google-creds service-account.json=@/tmp/google-creds.json

vault kv put secret/thanos-settings thanos.yaml=@/tmp/thanos-object-storage.yaml

vault kv put secret/logging-loki-gcp bucketname="vrutkovs-demo-loki"
vault kv patch secret/logging-loki-gcp key.json=@/tmp/google-creds.json

vault kv put secret/oauth-hub id="c42f5da56269e2226ea9" secret=@/tmp/oauth-hub
vault kv put secret/oauth-dev id="4d7b2c37541942c402a6" secret=@/tmp/oauth-dev
vault kv put secret/oauth-stage id="ffcf97a3b3342cf4e019" secret=@/tmp/oauth-stage
vault kv put secret/oauth-prod-eu id="8aa91dd0426c1dbb71fa" secret=@/tmp/oauth-prod-eu
vault kv put secret/oauth-prod-us id="da1f688da70855392c68" secret=@/tmp/oauth-prod-us
EOF
