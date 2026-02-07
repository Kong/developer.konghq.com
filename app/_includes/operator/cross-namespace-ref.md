By default, {{ site.operator_product_name }} restricts references to resources within the same namespace for security. 
To enable cross-namespace references, you must use one of the following resources in the target namespace:

* `ReferenceGrant`: A standard [Kubernetes Gateway API resource](https://gateway-api.sigs.k8s.io/api-types/referencegrant/) used for authorizing references from Gateway API resources to other resources.
* `KongReferenceGrant`: A Kong-specific resource used for authorizing references from Kong resources to other resources.