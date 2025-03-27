<!--vale off-->
{% mermaid %}
flowchart TD
    A{Deployment type?} --> B(Traditional mode)
    A{Deployment type?} --> C(Hybrid mode)
    A{Deployment type?} --> D(DB-less mode)
    A{Deployment type?} --> E(Konnect DP)
    B ---> F{Enough hardware to 
    run another cluster?}
    C --> G(Upgrade CP first) & H(Upgrade DP second)
    D ----> K([Rolling upgrade])
    E ----> K
    G --> F
    F ---Yes--->I([Dual-cluster upgrade])
    F ---No--->J([In-place upgrade])
    H ---> K
    click K "/gateway/upgrade/rolling-upgrade/"
    click I "/gateway/upgrade/dual-cluster/"
    click J "/gateway/upgrade/in-place/"
{% endmermaid %}
<!--vale on-->

> _Figure 1: Choose an upgrade strategy based on your deployment type. For Traditional mode, choose a dual-cluster upgrade if you have enough resources, or an in-place upgrade if you don't have enough resources. For DB-less mode and {{site.konnect_short_name}} DPs, use a rolling upgrade. For Hybrid mode, use one of the Traditional mode strategies for CPs, and the rolling upgrade for DPs._