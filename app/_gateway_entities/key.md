---
title: Keys
content_type: reference
entities:
  - key

tags:
  - secrets-management

products:
    - gateway

description: A Key object holds a representation of asymmetric keys in various formats.

related_resources:
  - text: Key Set entity
    url: /gateway/entities/key-set/
  - text: Keyring
    url: /gateway/keyring/
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Securing {{site.base_gateway}}
    url: /gateway/security/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway/control-plane-resource-limits/


api_specs:
  - gateway/admin-ee
  - konnect/control-planes-config 

tools:
  - deck
  - admin-api
  - konnect-api

schema:
  api: gateway/admin-ee
  path: /schemas/Key

works_on:
  - on-prem
  - konnect
---

## What is a Key?

A Key object holds a representation of asymmetric keys, either public or private. When {{site.base_gateway}} or a [Kong plugin](/plugins/) requires a specific public or private key to perform certain operations, it can use this entity.

Keys currently support JWK and PEM formats. Both formats carry the same base information, such as the public and private keys, but may allow you to specify additional meta information. For example, the JWK format carries more information than PEM. One key pair can have multiple different representations (JWK or PEM) while being the same key.

## Schema

{% entity_schema %}

## Set up a Key

{% entity_example %}
type: key
data:
  name: example-key
  kid: example-key-id
  jwk: '{"kty": "RSA","use": "enc","kid": "example-key-id","d": "jpq-eutUC5uNpVfYdsEZacbC9w0C3tPwl6jCLa2WB2yj1WcQRLRR5TJwCoPHUXucsKhtG8oHcvknmXgo1TzMWxUiSP2fhnqr9GEA4SSCvMqMvSazbgTLKtq1ZLyCBbyjlEBg2Leo9H4rsnh8p09WRQAbkq9S3Aq5kmUTLScWMCZLD5WZ95TxBJa7jRq8Ij1J69WI0v0Omb_jNbXfCYMZHaGxQrIYifwYYMtcrn70VxF2n0jh6TR5MnYggZdr84JdjQ564C-9ENYmAwyfKcWJ1yqMkLpRmy4dXV-MpBKuCarG1JdCu-r15595YtzObNd84-4B9JvaoJdy3hUXBsYTsQ","n": "9mXXIzrcNUohBgRU7GWsFd5rrToLEVZtY7kQY-M_ASpXBoMpxsUmfp5fk39YHRGThwiVYFw-c3h97qOlHDWggq0PhjA_TxNp8ZcLNGybyDSnmJIBFbGU2JxCyX4AJm9RY4ZHCWlyzmMNu3uL22s6ydirSdfWt5dKBSW2STRUVXTslGKH3VE3zpMR4J2T81jhQsuwhrdXg3My6G90FJ5ltSaksVgiErIjqFiu1y5cEG5Gvhz99QoomHY0enKaX7mrT9XfQVtUWkbsf8Pwi3W-zsZsHQsjZZ8u9F0AdNRkCIheH3NCw46H1ouzARgxT3mTxEn8dcFzbRFOlOtoTw98nw","e": "AQAB","p": "_qAspCgjxg-3eICW8V6wUgN61KZVGRKHCHCK9JqDmOj9d09y14zuQ9j10WjvxK4NPzdQUygJlzDRhB9Dbk4AHVj9eIIoCH1kpYk0SYWOhgqgdtQzbzJjM3X_03geghifuQc9VnjZxGymXAukS7EIGWTNQzurcrM70_TKDBGoErs","q": "97pMGP30n_e-DMMFuOoKaNKn_NKrh8KBJJXu3Bux5gV4YXh_IDDGI7qSu_7lvP24vrzBq9pj4zoMviBpfSz9YKrA9-Rs2_S6RngWxYAIie2gbqsbJ2ZvqiehLmuo3oUJBknUqDJ6b_K8Hy42e70ZXH27PHEwNWvWuXpZIPtt2W0","dp": "9GRa1KjuRTFaoR-TQVLoG5_ZanfH4AvHbdNPnB0eSEsA1V59VOSg4KBCuN9mmzmP32hBAb_BDMu_nXfAagQV2hVLHDqZICTy0GvTsums9X0HrWZZg9YyHveYN6noZmgqDhcjyXavVfgO6PQHmtrtciotVeXU1n-v4e3nbBQaZPc","dq": "2tCTpv-qtCIAnQUmaM9RooVwHMF5AdGsgMRu170exi7OxknJAIYUfjquoZ_lDaqPJOtVppag5HTCDK5Uf1zd8iThjhUWkrL4VoZ8lrcg07QxoY9BzOuOdp3KoVY3M1YPQp60WF0-COQ_hssrFOFTJX9pg1n3WziF0g9f6uIrhYE","qi": "AgC9YSgEgkwr0ucJiO-wk7PSXcmsbxh-tR_Zs3oVH32yKa0GbRw68ocneLrL9_3lfK3EfvEbbhNuWFdpi6szExx9tWz9y4xKdax5AmkceY-yYaCFV353NgEipmeJL7-olT-YS93zjomhVzATZNl400uGJ3TC90rt6Be5rDGWhNg"}'
{% endentity_example %}
