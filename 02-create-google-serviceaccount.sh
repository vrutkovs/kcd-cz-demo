set +eux

sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
sudo dnf install -y google-cloud-cli

gcloud iam service-accounts create vrutkovs --description="vrutkovs" --display-name="vrutkovs"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/compute.admin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/compute.loadBalancerAdmin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/dns.admin"
# gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
#   --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
#   --role="roles/iam.organizationRoleViewer"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountKeyAdmin"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding openshift-gce-devel --condition=None \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
gcloud iam service-accounts keys create \
  ~/src/github.com/vrutkovs/okd-installer/.gcp/credentials \
  --iam-account="vrutkovs@openshift-gce-devel.iam.gserviceaccount.com"
cp -rvf ~/src/github.com/vrutkovs/okd-installer/.gcp/credentials secrets/google-creds.json
/home/vrutkovs/.local/bin/yq e '.config.service_account=load_str("secrets/google-creds.json")' -i secrets/thanos-object-storage.yaml
