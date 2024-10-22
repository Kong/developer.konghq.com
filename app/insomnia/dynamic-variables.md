---
title: About dynamic variables 

content_type: reference
layout: reference

products:
    - insomnia

related_resources:
  - text: 
    url: 

tags:
  - test-apis

faqs:
  - q: 
    a: 
---


Insomnia has a feature that allows you to use pre-configured, random variables in your requests, request body, or environment. To do this, it uses the [Faker](https://www.npmjs.com/package/@faker-js/faker) library.

Dynamic variables allow you to easily test your endpoints using example values, like UUIDs, emails, and usernames.

## How do I use dynamic variables in Insomnia?

To use dynamic variables, start typing in a response, response body, or environment variable and a drop down menu displays with the different dynamic variables you can use. 

You can also import any collections with dynamic variables from Postman into Insomnia. The Postman dynamic variables are automatically converted to Insomnia variables.

## Which dynamic variables are available?

The following sections show which variables you can use and what they do.

### Common

| Variable name | Description | Example values |
| ------------- | ----------- | -------------- |
| `guid`  | A `uuid-v4` style guid | `4a6a9017-6052-41d7-8ba4-357d384ff807` |
| `timestamp` | The current UNIX timestamp in seconds | `1710442472227` |
| `isoTimestamp` | The current ISO timestamp at zero UTC | `2024-06-20T02:48:50.131Z` |
| `randomUUID` | A random 36-character UUID | `6f8c90d2-0d0b-413a-8346-37a351213a81` |

### Text, numbers, and colors

| Variable name | Description | Example values |
| ------------- | ----------- | -------------- |
| `randomAlphaNumeric` | A random alpha-numeric character | `b` |
| `randomBoolean` | A random boolean value | `true` |
| `randomInt` | A random integer | `7364467360811529` |
| `randomColor` | A random color | `gold` |
| `randomHexColor` | A random hex value | `#55065b` |
| `randomAbbreviation` | A random abbreviation | `EXE` |

### Internet and IP addresses

| Variable name | Description | Example values |
| ------------- | ----------- | -------------- |
| `randomIP` | A random IPv4 address | `212.131.240.145` |
| `randomIPV6` | A random IPv6 address | `c299:4d03:6b8b:ed2f:4b51:6546:5b94:b917` |
| `randomMACAddress` | A random MAC address | `d4:6b:84:2e:58:a4` |
| `randomPassword` | A random 15-character alpha-numeric password | `ipIDJxGJfBZ9a4d` |
| `randomLocale` | A random two-letter language code (ISO 3166-1) | `AO` |
| `randomUserAgent` | A random user agent | `Mozilla/5.0 (Windows NT 6.1; Trident/7.0; Touch; rv:11.0) like Gecko` |
| `randomProtocol` | A random internet protocol | `https` |
| `randomSemver` | A random semantic version number | `5.8.6` |


### Names

| Variable name        | Description                      | Example values                          |
|----------------------|----------------------------------|-----------------------------------------|
| `randomFirstName`     | A random first name              | `Ursula`                 |
| `randomLastName`      | A random last name               | `Kassulke`              |
| `randomFullName`      | A random first and last name     | `Flora Hodkiewicz` |
| `randomNamePrefix`     | A random name prefix             | `Miss`                           |
| `randomNameSuffix`     | A random name suffix             | `IV`                              |


### Profession

| Variable name         | Description                     | Example values                        |
|-----------------------|---------------------------------|---------------------------------------|
| `randomJobArea`        | A random job area               |      |
| `randomJobDescriptor`   | A random job descriptor          |             |
| `randomJobTitle`       | A random job title              |         |
| `randomJobType`        | A random job type               |       |

