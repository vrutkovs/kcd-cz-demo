set +x
gcloud iam service-accounts create vrutkovs --description="vrutkovs" --display-name="vrutkovs"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/compute.admin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/compute.loadBalancerAdmin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/dns.admin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.organizationRoleViewer"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountKeyAdmin"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding  openshift-gce-devel \
  --member="serviceAccount:vrutkovs@openshift-gce-devel.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
gcloud iam service-accounts keys create \
  ~/src/github.com/vrutkovs/okd-installer/.gcp/credentials \
  --iam-account="vrutkovs@openshift-gce-devel.iam.gserviceaccount.com"
cp -rvf ~/src/github.com/vrutkovs/okd-installer/.gcp/credentials secrets/google-creds.json
