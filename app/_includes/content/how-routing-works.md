For each incoming request, {{site.base_gateway}} must determine which Service gets to handle it based on the Routes that are defined. {{site.base_gateway}} handles routing in the following order:

1. {{site.base_gateway}} finds Routes that match the request by comparing the defined routing attributes with the attributes in the request. 
1. If multiple Routes match, the {{site.base_gateway}} router then orders all defined Routes by their priority and uses the highest priority matching Route to handle a request. 

If there are multiple matching Routes with the same priority, it is not defined
which of the matching Routes will be used and {{site.base_gateway}}
will use either of them according to how its internal data structures
are organized. If two or more Routes are configured with fields containing the same values, {{site.base_gateway}} applies a priority rule. {{site.base_gateway}} first tries to match the Routes with the most rules.