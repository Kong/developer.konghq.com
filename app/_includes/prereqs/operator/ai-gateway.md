Create an [{{ site.ai_gateway }}](/ai-gateway/) control plane, an OpenAI [AI Model Provider](/ai-gateway/entities/ai-model-provider/), a `gpt-4o-mini` [AI Model](/ai-gateway/entities/ai-model/), and a data plane.

1. Store your OpenAI API key in a Secret:

   ```bash
   kubectl create secret generic openai-credentials -n kong \
     --from-literal=token="Bearer ${OPENAI_API_KEY}"
   kubectl label secret openai-credentials -n kong konghq.com/secret=true
   ```

1. Create the {{ site.ai_gateway }} resources:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: KonnectAIGateway
   metadata:
     name: my-ai-gateway-cp
     namespace: kong
   spec:
     apiSpec:
       name: my-ai-gateway-cp
       displayName: My AI Gateway
     konnect:
       authRef:
         name: konnect-api-auth
   ---
   apiVersion: aiconfiguration.konghq.com/v1alpha1
   kind: AIGatewayModelProvider
   metadata:
     name: openai-provider
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       type: openai
       openai:
         name: openai-provider
         displayName: OpenAI
         config:
           auth:
             headers:
               - name: Authorization
                 value:
                   type: secretRef
                   secretRef:
                     name: openai-credentials
                     key: token
   ---
   apiVersion: aiconfiguration.konghq.com/v1alpha1
   kind: AIGatewayModel
   metadata:
     name: gpt-4o-mini
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       type: model
       model:
         name: gpt-4o-mini
         displayName: GPT-4o Mini
         enabled: Enabled
         formats:
           - type: openai
         capabilities:
           - generate
         config:
           route:
             paths:
               - /v1
         targets:
           - name: gpt-4o-mini
             provider:
               name: openai-provider
             config:
               type: openai
               openai:
                 upstreamURL: https://api.openai.com/v1/chat/completions
   ---
   apiVersion: aigateway.konghq.com/v1alpha1
   kind: AIGatewayDataPlane
   metadata:
     name: my-ai-gateway-dp
     namespace: kong
   spec:
     controlPlaneRef:
       type: konnectNamespacedRef
       konnectNamespacedRef:
         name: my-ai-gateway-cp
     deployment:
       replicas: 1
     network:
       services:
         ingress:
           type: LoadBalancer
           ports:
             - name: http
               port: 8000
               targetPort: 8000
   ' | kubectl apply -f -
   ```
   {:.collapsible}

1. Wait for the resources to be ready:

   ```bash
   kubectl wait konnectaigateway/my-ai-gateway-cp aigatewaymodelprovider/openai-provider aigatewaymodel/gpt-4o-mini -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   kubectl wait aigatewaydataplane/my-ai-gateway-dp -n kong \
     --for=condition=Ready=True \
     --timeout=10m
   ```

1. Export the data plane address:

   ```bash
   export AIGW_HOST=$(kubectl get service my-ai-gateway-dp-ingress -n kong \
     -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $AIGW_HOST
   ```
