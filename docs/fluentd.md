# Centralized logging with a Customized fluentd

The demostrated architecture in this project separates the in-scope and out-of-scope
traffic not only in to two separate clusters, but those clusters reside in two separate projects as well. The default logging settings of GKE clusters is to include a `fluentd` agent that sends its logs to a Stackdriver Logging target located in its project. If not customized, that would cause the in-scope application's logs to go to the in-scope project's Stackdriver, and respectively the out-of-scope applications to the out-of-scope Stackdriver. Separate logging targets may be desirable in some situations, but in this case, it was consdired more desirable to have the logs consolidated to a single Stackdriver Logging project as its target.

In order to accomplish this, the default GKE logging is unset, visible in the terraform [here](/terraform/components/out-of-scope/cluster.tf#L46) and [here](/terraform/components/in-scope/cluster.tf#L46). Then, as described in the installation steps in the readme, a helm chart with
a custom `fluentd` configuration is installed. The helm chart's are configured to be identical to the default GKE logging configuration, aside from the change of the target project. This is the relevant excerpt from the fluentd-custom-target-project chart (the parallel change is made in the fluentd-filter-dlp chart):

```
...
<match kubernetes.**>
      @type google_cloud
      project_id {{ .Values.project_id }}
...
<match **>
  @type google_cloud
  project_id {{ .Values.project_id }}
```

Customizing the logging agent is discussed in [Configuring the Agent](https://cloud.google.com/logging/docs/agent/configuration).
