<!-- used on /gateway/entities/upstream/ and /gateway/entities/targets/ -->
You can set `failover: true` to indicate that a Target should be used as a failover (backup) Target in case the other, regular targets (`failover: false`) associated with an Upstream are unhealthy. The failover Target is only used when *all* regular Targets are unhealthy. You can set one or multiple failover Targets for an Upstream. 

Failover Targets are supported by the [latency](/gateway/entities/upstream/#latency), [least-connections](/gateway/entities/upstream/#least-connections), and [round-robin](/gateway/entities/upstream/#round-robin) load balancing algorithms. 

{:.info}
> **Note**: If you set failover Targets for Upstreams with the [consistent-hashing](/gateway/entities/upstream/#consistent-hashing) or [sticky session](/gateway/entities/upstream/#sticky-sessions) load balancing algorithms, they *won't* be used for regular load balancing or as a failover.

The following is an example failover Target configuration:

{% entity_example %}
type: target
data:
  target: 192.168.1.3:8080
  weight: 50
  failover: true 
{% endentity_example %}

For a complete tutorial, see [Route requests to backup Targets during failures](/how-to/route-requests-to-backup-targets/).