Supported in: {% new_in 3.11 %}

```
curl -s -D >(grep -i x-request-id >&2) \
  -o >(jq -r '.data[0].b64_json' | base64 --decode > breakfast-platter.png) \
  -X POST "https://api.openai.com/v1/images/edits" \
  -F "image=@pancakes.png" \
  -F "image=@coffee-cup.png" \
  -F "image=@fruit-bowl.png" \
  -F "image=@orange-juice.png" \
  -F 'prompt=Create a delicious breakfast platter with these four items arranged beautifully'

```