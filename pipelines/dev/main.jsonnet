local subscription = std.parseYaml(importstr 'manifests/01-subscription.yaml');
local tekton_settings = std.parseYaml(importstr 'manifests/02-tekton-settings.yaml');
local pipeline = std.parseYaml(importstr 'manifests/03-build-pipeline.yaml');
local pipeline_run = std.parseYaml(importstr 'manifests/04-pipeline-run.yaml');

[subscription, tekton_settings, pipeline, pipeline_run]
