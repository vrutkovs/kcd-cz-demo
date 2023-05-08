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
        command:
        - bash
        - -c
        - |
          oc apply -f - <<EOF
          apiVersion: tekton.dev/v1beta1
          kind: PipelineRun
          metadata:
            name: dev-run
          spec:
            pipelineRef:
              name: deploy-to-stage
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
                        storage: 1Gi
                    storageClassName: gp3-csi
                    volumeMode: Filesystem
          EOF
