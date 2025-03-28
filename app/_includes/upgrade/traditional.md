A [Traditional mode](/gateway/traditional-mode/) deployment is when all {{site.base_gateway}} components are running in one environment, 
and there is no Control Plane/Data Plane separation.

You have two options when upgrading {{site.base_gateway}} in Traditional mode:
* [Dual-cluster upgrade](/gateway/upgrade/dual-cluster/): 
A new {{site.base_gateway}} cluster of version Y is deployed alongside the current version X, so that two 
clusters serve requests concurrently during the upgrade process.
* [In-place upgrade](/gateway/upgrade/in-place/): An in-place upgrade reuses 
the existing database and has to shut down cluster X first, then configure the new cluster Y to point 
to the database.

We recommend using a dual-cluster upgrade if you have the resources to run another cluster concurrently.
Use the in-place method only if resources are limited, as it will cause business downtime.