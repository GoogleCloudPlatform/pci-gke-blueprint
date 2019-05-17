# Audit and Flow Logs

This project includes a demonstration of three log sinks. The terraform configuration
that manages these resources is in
[terraform/components/logging/main.tf](/terraform/components/logging/main.tf).

It includes:

1. All Admin Activity with severity >= Warning throughout the folder's projects
1. All GCE logs of the in-scope project
1. All VPC Flow logs (from the network project), specific to the in-scope subnet

A single bucket, PROJECT_PREFIX-logging-bucket in the management project is
configured as the log sinks' target.


## Documentation
 * [Exporting Logs in the API > Introduction to sinks](https://cloud.google.com/logging/docs/api/tasks/exporting-logs#introduction_to_sinks)
 * [Advanced Logs Filters](https://cloud.google.com/logging/docs/view/advanced-filters)
 * [Advanced filters library](https://cloud.google.com/logging/docs/view/filters-library)
