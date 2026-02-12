To complete this tutorial, you must have a Guardrail policy created in your AWS Bedrock account:

1. **Install AWS CLI v2**
   Follow [the official installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
   After installation, confirm it by running:

   ```bash
   aws --version
   ````

2. **Configure AWS credentials**
   Run the following command and provide your IAM user or role credentials:

   ```bash
   aws configure
   ```

   You will be prompted to enter:

   * AWS Access Key ID
   * AWS Secret Access Key
   * Default region name (e.g., `us-east-1`)
   * Default output format (e.g., `json`)

   Make sure your IAM user or role has Bedrock permissions such as `bedrock:CreateGuardrail`, `bedrock:CreateGuardrailVersion`, and others necessary for managing guardrails.
   For more details, see the [AWS CLI configuration documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

3. Test that you can call Bedrock operations by running:

   ```bash
   aws bedrock list-foundation-models
   ```

   If this command fails, check your credentials, permissions, and configured region.

4. Create a `guardrail.json` configuration file:
   This configuration defines an Amazon Bedrock guardrail named `example-guardrail` that blocks harmful or restricted content—including specific words, topics like quantum computing, and categories such as violence, hate, and prompt attacks—in both input and output messages.

   ```
   cat <<'EOF' > guardrail.json
   {
     "name": "example-guardrail",
     "description": "My first Bedrock guardrail via CLI",
     "blockedInputMessaging": "Input blocked due to policy violation.",
     "blockedOutputsMessaging": "Output blocked due to policy violation.",
     "wordPolicyConfig": {
       "wordsConfig": [
         {
           "inputAction": "BLOCK",
           "inputEnabled": true,
           "outputAction": "BLOCK",
           "outputEnabled": true,
           "text": "badword1"
         },
         {
           "inputAction": "BLOCK",
           "inputEnabled": true,
           "outputAction": "BLOCK",
           "outputEnabled": true,
           "text": "badword2"
         }
       ]
     },
     "topicPolicyConfig": {
       "topicsConfig": [
         {
           "name": "quantum computing",
           "definition": "Anything related to quantum computing",
           "examples": [],
           "type": "DENY",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK",
           "inputEnabled": true,
           "outputEnabled": true
         }
       ]
     },
     "contentPolicyConfig": {
       "filtersConfig": [
         {
           "type": "VIOLENCE",
           "inputStrength": "HIGH",
           "outputStrength": "HIGH",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK"
         },
         {
           "type": "PROMPT_ATTACK",
           "inputStrength": "HIGH",
           "outputStrength": "NONE",
           "inputAction": "BLOCK"
         },
         {
           "type": "MISCONDUCT",
           "inputStrength": "HIGH",
           "outputStrength": "HIGH",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK"
         },
         {
           "type": "HATE",
           "inputStrength": "HIGH",
           "outputStrength": "HIGH",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK"
         },
         {
           "type": "SEXUAL",
           "inputStrength": "HIGH",
           "outputStrength": "HIGH",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK"
         },
         {
           "type": "INSULTS",
           "inputStrength": "HIGH",
           "outputStrength": "HIGH",
           "inputAction": "BLOCK",
           "outputAction": "BLOCK"
         }
       ]
     }
   }
   EOF
   ```

5. Apply this configuration by running the following command in your terminal:

    ```bash
    aws bedrock create-guardrail \
    --cli-input-json file://$HOME/guardrail.json \
    --region $DECK_AWS_REGION
    ```

    If successful, your terminal will output the following:

    ```json
    {
        "guardrailId": "0abcs5r0q3abcd",
        "guardrailArn": "arn:aws:bedrock:us-east-1:111111141111:guardrail/0nhw5r0q3abcd",
        "version": "DRAFT",
        "createdAt": "2025-06-18T08:49:40.678019+00:00"
    }
    ```

    Export the Guardrail ID and Guardrail version as environment variables:

    ```bash
    export DECK_GUARDRAILS_ID=0abcs5r0q3abcd
    export DECK_GUARDRAILS_VERSION=DRAFT
    ```