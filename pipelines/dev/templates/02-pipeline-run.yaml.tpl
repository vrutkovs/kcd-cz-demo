apiVersion: batch/v1
kind: Job
metadata:
  generateName: start-pipeline
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: pipeline
      containers:
      - name: start-pipeline
        image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
        env:
        - name: REPO_URL
          value: "{{ .Values.repo_url }}"
        - name: REPO_SHA
          value: "{{ .Values.repo_sha }}"
        command:
        - bash
        - -c
        - |
          oc apply -f - <<EOF
          apiVersion: tekton.dev/v1beta1
          kind: PipelineRun
          metadata:
            name: "dev-run-{{ .Values.repo_sha }}"
          spec:
            params:
              - name: repo-url
                value: "${REPO_URL}"
              - name: repo-revision
                value: "${REPO_SHA}"
            pipelineRef:
              name: deploy-preview-from-pr
            timeout: 1h0m0s
            workspaces:
              - name: app-source
                volumeClaimTemplate:
                  metadata:
                    creationTimestamp: null
                  spec:
                    accessModes:
                      - ReadWriteOnce
                    resources:
                      requests:
                        storage: 100Mi
                    storageClassName: gp3-csi
                    volumeMode: Filesystem
          EOF
