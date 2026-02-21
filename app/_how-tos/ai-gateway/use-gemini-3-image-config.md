---
title: Use Gemini's imageConfig with AI Proxy in {{site.ai_gateway}}
permalink: /how-to/use-gemini-3-image-config/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Gemini Image Generation
    url: https://ai.google.dev/gemini-api/docs/imagen

description: "Configure the AI Proxy plugin to use Gemini's `imageConfig` parameters for controlling image generation aspect ratio and resolution."

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - gemini
  - ai-sdks

tldr:
  q: How do I use Gemini's imageConfig with the AI Proxy plugin?
  a: Configure the AI Proxy plugin with the Gemini provider and gemini-3-pro-image-preview model, then pass imageConfig parameters via generationConfig in your image generation requests.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex AI
      include_content: prereqs/vertex-ai
      icon_url: /assets/icons/gcp.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
    - title: OpenAI SDK and required libraries
      content: |
        Install the OpenAI SDK the requests library:
        ```sh
        pip install openai requests
        ```
      icon_url: /assets/icons/openai.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: What version of {{site.base_gateway}} supports imageConfig?
    a: |
      The `imageConfig` feature requires {{site.base_gateway}} 3.13 or later.
  - q: What aspect ratios are supported?
    a: |
      Gemini 3 supports aspect ratios including `1:1` (square), `4:3`, and `16:9`. Refer to the Gemini documentation for a complete list of supported ratios.
  - q: What image sizes are available?
    a: |
      The `imageSize` parameter accepts values like `1k`, `2k`, and `4k`. Higher values produce higher resolution images but may increase generation time.
---

## Configure the plugin

Configure AI Proxy to use the gemini-3-pro-image-preview model for image generation via Vertex AI:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        genai_category: image/generation
        route_type: "image/v1/images/generations"
        logging:
          log_payloads: false
          log_statistics: true
        model:
          provider: gemini
          name: gemini-3-pro-image-preview
          options:
            gemini:
              api_endpoint: aiplatform.googleapis.com
              project_id: ${gcp_project_id}
              location_id: global
        auth:
          allow_override: false
          gcp_use_service_account: true
          gcp_service_account_json: ${gcp_service_account_json}
variables:
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
{% endentity_examples %}

## Use imageConfig with image generation

Gemini 3 models support image generation with configurable parameters via `imageConfig`. This feature allows you to control the aspect ratio and resolution of generated images. For more information, see [Gemini Image Generation](https://ai.google.dev/gemini-api/docs/imagen).

The `imageConfig` supports the following parameters:

* `aspectRatio` (string): Controls the aspect ratio of the generated image. Supported values include `1:1`, `4:3`, `16:9`, and others.
* `imageSize` (string): Controls the resolution of the generated image. Accepted values include `1k`, `2k`, and `4k`.

{{site.base_gateway}} now supports passing `generationConfig` parameters through to Gemini. Any parameters within reasonable size limits will be forwarded to the Gemini API, allowing you to use Gemini-specific features like `imageConfig`.

Create a Python script to generate images with different configurations:

```py
cat << 'EOF' > generate-images.py
#!/usr/bin/env python3
"""Generate images with Gemini 3 via {{site.ai_gateway}} using imageConfig"""
import requests
import base64
BASE_URL = "http://localhost:8000/anything"
print("Generating images with Gemini 3 imageConfig")
print("=" * 50)
# Example 1: 4:3 aspect ratio, 1k resolution
print("\n=== Example 1: 4:3 Aspect Ratio, 1k Size ===")
try:
    response = requests.post(
        BASE_URL,
        headers={"Content-Type": "application/json"},
        json={
            "model": "gemini-3-pro-image-preview",
            "prompt": "Generate a simple red circle on white background",
            "n": 1,
            "generationConfig": {
                "imageConfig": {
                    "aspectRatio": "4:3",
                    "imageSize": "1k"
                }
            }
        }
    )
    response.raise_for_status()
    data = response.json()
    print(f"✓ Image generated (4:3, 1k)")
    image_data = data['data'][0]
    if 'url' in image_data:
        img_response = requests.get(image_data['url'])
        with open("circle_4x3_1k.png", "wb") as f:
            f.write(img_response.content)
        print(f"Saved to circle_4x3_1k.png")
    elif 'b64_json' in image_data:
        image_bytes = base64.b64decode(image_data['b64_json'])
        with open("circle_4x3_1k.png", "wb") as f:
            f.write(image_bytes)
        print(f"Saved to circle_4x3_1k.png")
except Exception as e:
    print(f"Failed: {e}")
# Example 2: 16:9 aspect ratio, 2k resolution
print("\n=== Example 2: 16:9 Aspect Ratio, 2k Size ===")
try:
    response = requests.post(
        BASE_URL,
        headers={"Content-Type": "application/json"},
        json={
            "model": "gemini-3-pro-image-preview",
            "prompt": "A minimalist landscape with mountains and a sunset",
            "n": 1,
            "generationConfig": {
                "imageConfig": {
                    "aspectRatio": "16:9",
                    "imageSize": "2k"
                }
            }
        }
    )
    response.raise_for_status()
    data = response.json()
    print(f"✓ Image generated (16:9, 2k)")
    image_data = data['data'][0]
    if 'url' in image_data:
        img_response = requests.get(image_data['url'])
        with open("landscape_16x9_2k.png", "wb") as f:
            f.write(img_response.content)
        print(f"Saved to landscape_16x9_2k.png")
    elif 'b64_json' in image_data:
        image_bytes = base64.b64decode(image_data['b64_json'])
        with open("landscape_16x9_2k.png", "wb") as f:
            f.write(image_bytes)
        print(f"Saved to landscape_16x9_2k.png")
except Exception as e:
    print(f"Failed: {e}")
# Example 3: 1:1 aspect ratio, 4k resolution
print("\n=== Example 3: 1:1 Aspect Ratio, 4k Size ===")
try:
    response = requests.post(
        BASE_URL,
        headers={"Content-Type": "application/json"},
        json={
            "model": "gemini-3-pro-image-preview",
            "prompt": "A 24px by 24px green capital letter 'A' with a subtle shadow on white background",
            "n": 1,
            "generationConfig": {
                "imageConfig": {
                    "aspectRatio": "1:1",
                    "imageSize": "4k"
                }
            }
        }
    )
    response.raise_for_status()
    data = response.json()
    print(f"✓ Image generated (1:1, 4k)")
    image_data = data['data'][0]
    if 'url' in image_data:
        img_response = requests.get(image_data['url'])
        with open("letter_a_1x1_4k.png", "wb") as f:
            f.write(img_response.content)
        print(f"Saved to letter_a_1x1_4k.png")
    elif 'b64_json' in image_data:
        image_bytes = base64.b64decode(image_data['b64_json'])
        with open("letter_a_1x1_4k.png", "wb") as f:
            f.write(image_bytes)
        print(f"Saved to letter_a_1x1_4k.png")
except Exception as e:
    print(f"Failed: {e}")
print("\n" + "=" * 50)
print("Complete")
EOF
```

This script demonstrates three different image generation configurations:

1. **4:3 aspect ratio with 1k resolution**: Generates a simple shape with standard definition.
2. **16:9 aspect ratio with 2k resolution**: Produces a widescreen landscape with higher resolution.
3. **1:1 aspect ratio with 4k resolution**: Creates a square image with maximum resolution.

The script uses the OpenAI Images API format (`/v1/images/generations` endpoint) with the `generationConfig` parameter to pass Gemini-specific configuration. {{site.ai_gateway}} forwards these parameters to Vertex AI and returns the generated images as either URLs or base64-encoded data. The script handles both response formats and saves the images locally.

Run the script:
```sh
python3 generate-images.py
```

Example output:
```text
Generating images with Gemini 3 imageConfig
==================================================

=== Example 1: 4:3 Aspect Ratio, 1k Size ===
✓ Image generated (4:3, 1k)
Saved to circle_4x3_1k.png

=== Example 2: 16:9 Aspect Ratio, 2k Size ===
✓ Image generated (16:9, 2k)
Saved to landscape_16x9_2k.png

=== Example 3: 1:1 Aspect Ratio, 4k Size ===
✓ Image generated (1:1, 4k)
Saved to letter_a_1x1_4k.png

==================================================
Complete
```

Open the generated images:

```sh
open circle_4x3_1k.png
open landscape_16x9_2k.png
open letter_a_1x1_4k.png
```

The script generates three images with different aspect ratios and resolutions, demonstrating how `imageConfig` controls the output dimensions and quality. All generated images are saved to the current directory.