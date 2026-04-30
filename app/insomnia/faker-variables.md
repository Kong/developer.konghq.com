---
title: Faker Variables
content_type: reference
layout: reference

products:
 - insomnia

tags:
- mock-servers


description: Generate random data from Liquid faker variables in Insomnia mock servers with dynamic mocking.

breadcrumbs:
  - /insomnia/

related_resources:
  - text: Mocks
    url: /insomnia/mock-servers/
  - text: Self-hosted mocks
    url: /insomnia/self-hosted-mocks/
  - text: Storage options
    url: /insomnia/storage/
  - text: Requests
    url: /insomnia/requests/
  - text: Template tags
    url: /insomnia/template-tags/
  - text: Dynamic mocking
    url: /insomnia/dynamic-mocking/
---

Use [Faker functions](https://github.com/Kong/insomnia/blob/develop/packages/insomnia/src/templating/faker-functions.ts) anywhere template tags are supported to generate realistic mock data like names, emails, or timestamps.

Faker output varies per call. Example values in the tables are illustrative.

## Usage

Generate random fake data when making a request in Insomnia by including the `faker.` prefix before the variable name. Use this format wherever template tags are supported, such as the Body pane:

```liquid
{% raw %}{{ faker.<variable-name> }}{% endraw %}
```

For example:

```liquid
{% raw %}{{ faker.randomFullName }}{% endraw %}
```

## Common identifiers

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`guid`"
    desc: "A globally unique identifier (UUID v4). Alias of `randomUUID`."
    ex: "`611c2e81-2ccb-42d8-9ddc-2d0bfa65c1b4`"
  - var: "`randomUUID`"
    desc: "A globally unique identifier (UUID v4)."
    ex: "`6929bb52-3ab2-448a-9796-d6480ecad36b`"
  - var: "`randomAlphaNumeric`"
    desc: "A random alphanumeric character."
    ex: "`y`"
  - var: "`randomBoolean`"
    desc: "A random boolean value."
    ex: "`true`"
  - var: "`randomInt`"
    desc: "A random integer."
    ex: "`710`"
  - var: "`timestamp`"
    desc: "The current Unix timestamp in milliseconds."
    ex: "`1761234567890`"
  - var: "`isoTimestamp`"
    desc: "The current timestamp in ISO 8601 format."
    ex: "`2026-04-29T14:32:10.123Z`"
{% endtable %}
<!-- vale on -->

## Colors

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomColor`"
    desc: "A random human-readable color name."
    ex: "`turquoise`"
  - var: "`randomHexColor`"
    desc: "A random color as a hex value."
    ex: "`#a3e1f4`"
{% endtable %}
<!-- vale on -->

## Text, numbers, and dates

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomAbbreviation`"
    desc: "A random tech-style abbreviation."
    ex: "`SSL`"
  - var: "`randomSemver`"
    desc: "A random semantic version string."
    ex: "`7.4.1`"
  - var: "`randomDateFuture`"
    desc: "A random ISO timestamp in the future."
    ex: "`2027-08-12T03:14:22.000Z`"
  - var: "`randomDatePast`"
    desc: "A random ISO timestamp in the past."
    ex: "`2024-02-09T11:08:51.000Z`"
  - var: "`randomDateRecent`"
    desc: "A random ISO timestamp from the recent past."
    ex: "`2026-04-26T10:42:11.000Z`"
  - var: "`randomWeekday`"
    desc: "A random day of the week."
    ex: "`Tuesday`"
  - var: "`randomMonth`"
    desc: "A random month of the year."
    ex: "`September`"
  - var: "`randomNoun`"
    desc: "A random tech-themed noun. Aliased by `randomWord`."
    ex: "`bandwidth`"
  - var: "`randomVerb`"
    desc: "A random tech-themed verb."
    ex: "`parse`"
  - var: "`randomIngverb`"
    desc: "A random tech-themed verb in the `-ing` form."
    ex: "`compressing`"
  - var: "`randomAdjective`"
    desc: "A random tech-themed adjective."
    ex: "`virtual`"
  - var: "`randomWord`"
    desc: "A random word. Alias of `randomNoun`."
    ex: "`firewall`"
  - var: "`randomWords`"
    desc: "Several random words. Alias of `randomLoremWords`."
    ex: "`alias bandwidth port`"
  - var: "`randomPhrase`"
    desc: "A random tech-themed phrase."
    ex: "`Try to override the SSL pixel, maybe it will calculate the cross-platform port!`"
  - var: "`randomLoremWord`"
    desc: "A single lorem ipsum word."
    ex: "`magnam`"
  - var: "`randomLoremWords`"
    desc: "Several lorem ipsum words."
    ex: "`fugiat dolorem voluptas`"
  - var: "`randomLoremSentence`"
    desc: "A lorem ipsum sentence."
    ex: "`Voluptatem quia repudiandae numquam.`"
  - var: "`randomLoremSentences`"
    desc: "Multiple lorem ipsum sentences."
    ex: "`Quia repudiandae. Numquam optio dolor.`"
  - var: "`randomLoremParagraph`"
    desc: "A lorem ipsum paragraph."
    ex: "`Voluptatem quia repudiandae numquam optio...`"
  - var: "`randomLoremParagraphs`"
    desc: "Multiple lorem ipsum paragraphs."
    ex: "`Voluptatem quia... \\n Numquam optio...`"
  - var: "`randomLoremText`"
    desc: "A block of lorem ipsum text."
    ex: "`Quaerat voluptatem repudiandae...`"
  - var: "`randomLoremSlug`"
    desc: "A lorem ipsum slug."
    ex: "`magnam-fugiat-dolorem`"
  - var: "`randomLoremLines`"
    desc: "Several lorem ipsum lines separated by newlines."
    ex: "`Quaerat voluptatem.\\nRepudiandae numquam.`"
{% endtable %}
<!-- vale on -->

## Internet, IP, and web

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomPhoneNumber`"
    desc: "A random phone number. `randomPhoneNumberExt` is an alias."
    ex: "`692-980-3551`"
  - var: "`randomPhoneNumberExt`"
    desc: "A random phone number. Alias of `randomPhoneNumber`."
    ex: "`692-980-3551`"
  - var: "`randomIP`"
    desc: "A random IPv4 address."
    ex: "`192.0.2.146`"
  - var: "`randomIPV6`"
    desc: "A random IPv6 address."
    ex: "`2001:0db8:85a3:0000:0000:8a2e:0370:7334`"
  - var: "`randomMACAddress`"
    desc: "A random MAC address."
    ex: "`a1:b2:c3:d4:e5:f6`"
  - var: "`randomPassword`"
    desc: "A random password string."
    ex: "`8X3kP2qLm9vN`"
  - var: "`randomLocale`"
    desc: "A random ISO country code. (Returns a country code, not a full locale.)"
    ex: "`FR`"
  - var: "`randomUserAgent`"
    desc: "A random browser user agent string."
    ex: "`Mozilla/5.0 (Windows NT 10.0)...`"
  - var: "`randomProtocol`"
    desc: "A random URL protocol."
    ex: "`https`"
  - var: "`randomDomainName`"
    desc: "A random fully qualified domain name."
    ex: "`fluffy-buyer.biz`"
  - var: "`randomDomainSuffix`"
    desc: "A random domain suffix."
    ex: "`io`"
  - var: "`randomDomainWord`"
    desc: "A random single domain word."
    ex: "`fluffy-buyer`"
  - var: "`randomEmail`"
    desc: "A random email address."
    ex: "`Eliza_Schaden@hotmail.com`"
  - var: "`randomExampleEmail`"
    desc: "A random email at example.com / example.org."
    ex: "`Eliza_Schaden@example.com`"
  - var: "`randomUserName`"
    desc: "A random username."
    ex: "`Eliza.Schaden42`"
  - var: "`randomUrl`"
    desc: "A random URL."
    ex: "`https://fluffy-buyer.biz`"
{% endtable %}
<!-- vale on -->

## Names and addresses

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomFirstName`"
    desc: "A random first name."
    ex: "`Ethan`"
  - var: "`randomLastName`"
    desc: "A random last name."
    ex: "`Olson`"
  - var: "`randomFullName`"
    desc: "A random full name."
    ex: "`Olga Stehr`"
  - var: "`randomNamePrefix`"
    desc: "A random name prefix."
    ex: "`Mrs.`"
  - var: "`randomNameSuffix`"
    desc: "A random name suffix."
    ex: "`Jr.`"
  - var: "`randomCity`"
    desc: "A random city name."
    ex: "`Spinkahaven`"
  - var: "`randomStreetName`"
    desc: "A random street name."
    ex: "`Kuhic Island`"
  - var: "`randomStreetAddress`"
    desc: "A random street address."
    ex: "`5742 Harvey Streets`"
  - var: "`randomCountry`"
    desc: "A random country name."
    ex: "`Lao People's Democratic Republic`"
  - var: "`randomCountryCode`"
    desc: "A random ISO country code."
    ex: "`CV`"
  - var: "`randomLatitude`"
    desc: "A random latitude coordinate."
    ex: "`55.2099`"
  - var: "`randomLongitude`"
    desc: "A random longitude coordinate."
    ex: "`113.1234`"
{% endtable %}
<!-- vale on -->

## Jobs

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomJobArea`"
    desc: "A random job area or specialty."
    ex: "`Tactics`"
  - var: "`randomJobDescriptor`"
    desc: "A random job descriptor."
    ex: "`Forward`"
  - var: "`randomJobTitle`"
    desc: "A random job title."
    ex: "`Forward Tactics Liaison`"
  - var: "`randomJobType`"
    desc: "A random job type."
    ex: "`Liaison`"
{% endtable %}
<!-- vale on -->

## Images

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomAvatarImage`"
    desc: "A random avatar image URL."
    ex: "`https://avatars.githubusercontent.com/u/12345678`"
  - var: "`randomImageUrl`"
    desc: "A random image URL."
    ex: "`https://loremflickr.com/640/480`"
  - var: "`randomImageDataUri`"
    desc: "A random image as a data URI."
    ex: "`data:image/svg+xml;charset=UTF-8,...`"
  - var: "`randomAbstractImage`"
    desc: "A random abstract-themed image URL."
    ex: "`https://loremflickr.com/640/480/abstract`"
  - var: "`randomAnimalsImage`"
    desc: "A random animals-themed image URL."
    ex: "`https://loremflickr.com/640/480/animals`"
  - var: "`randomBusinessImage`"
    desc: "A random business-themed image URL."
    ex: "`https://loremflickr.com/640/480/business`"
  - var: "`randomCatsImage`"
    desc: "A random cats-themed image URL."
    ex: "`https://loremflickr.com/640/480/cats`"
  - var: "`randomCityImage`"
    desc: "A random city-themed image URL."
    ex: "`https://loremflickr.com/640/480/city`"
  - var: "`randomFoodImage`"
    desc: "A random food-themed image URL."
    ex: "`https://loremflickr.com/640/480/food`"
  - var: "`randomNightlifeImage`"
    desc: "A random nightlife-themed image URL."
    ex: "`https://loremflickr.com/640/480/nightlife`"
  - var: "`randomFashionImage`"
    desc: "A random fashion-themed image URL."
    ex: "`https://loremflickr.com/640/480/fashion`"
  - var: "`randomPeopleImage`"
    desc: "A random people-themed image URL."
    ex: "`https://loremflickr.com/640/480/people`"
  - var: "`randomNatureImage`"
    desc: "A random nature-themed image URL."
    ex: "`https://loremflickr.com/640/480/nature`"
  - var: "`randomSportsImage`"
    desc: "A random sports-themed image URL."
    ex: "`https://loremflickr.com/640/480/sports`"
  - var: "`randomTransportImage`"
    desc: "A random transport-themed image URL."
    ex: "`https://loremflickr.com/640/480/transport`"
{% endtable %}
<!-- vale on -->

## Finance

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomBankAccount`"
    desc: "A random bank account number."
    ex: "`94872635`"
  - var: "`randomBankAccountName`"
    desc: "A random bank account name."
    ex: "`Savings Account`"
  - var: "`randomCreditCardMask`"
    desc: "A random masked credit card number."
    ex: "`4216`"
  - var: "`randomBankAccountBic`"
    desc: "A random BIC (Bank Identifier Code)."
    ex: "`DEUTDEFF`"
  - var: "`randomBankAccountIban`"
    desc: "A random IBAN (International Bank Account Number)."
    ex: "`DE89370400440532013000`"
  - var: "`randomTransactionType`"
    desc: "A random transaction type."
    ex: "`deposit`"
  - var: "`randomCurrencyCode`"
    desc: "A random ISO currency code."
    ex: "`EUR`"
  - var: "`randomCurrencyName`"
    desc: "A random currency name."
    ex: "`Euro`"
  - var: "`randomCurrencySymbol`"
    desc: "A random currency symbol."
    ex: "`€`"
  - var: "`randomBitcoin`"
    desc: "A random Bitcoin address."
    ex: "`1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa`"
{% endtable %}
<!-- vale on -->

## Business / Company

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomCompanyName`"
    desc: "A random company name."
    ex: "`Bashirian, Kunde and Price`"
  - var: "`randomCompanySuffix`"
    desc: "A random company name. Alias of `randomCompanyName`."
    ex: "`Bashirian, Kunde and Price`"
  - var: "`randomBs`"
    desc: "A random business buzz phrase."
    ex: "`unleash bricks-and-clicks portals`"
  - var: "`randomBsAdjective`"
    desc: "A random business buzz adjective."
    ex: "`bricks-and-clicks`"
  - var: "`randomBsBuzz`"
    desc: "A random business buzz verb."
    ex: "`unleash`"
  - var: "`randomBsNoun`"
    desc: "A random business buzz noun."
    ex: "`portals`"
  - var: "`randomCatchPhrase`"
    desc: "A random marketing catch phrase."
    ex: "`Synchronised systematic encryption`"
  - var: "`randomCatchPhraseAdjective`"
    desc: "A random catch phrase adjective."
    ex: "`Synchronised`"
  - var: "`randomCatchPhraseDescriptor`"
    desc: "A random catch phrase descriptor."
    ex: "`systematic`"
  - var: "`randomCatchPhraseNoun`"
    desc: "A random catch phrase noun."
    ex: "`encryption`"
{% endtable %}
<!-- vale on -->

## Database

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomDatabaseColumn`"
    desc: "A random database column name."
    ex: "`updated_at`"
  - var: "`randomDatabaseType`"
    desc: "A random database column type."
    ex: "`varchar`"
  - var: "`randomDatabaseCollation`"
    desc: "A random database collation."
    ex: "`utf8_general_ci`"
  - var: "`randomDatabaseEngine`"
    desc: "A random database engine."
    ex: "`InnoDB`"
{% endtable %}
<!-- vale on -->

## Files and systems

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomFileName`"
    desc: "A random file name."
    ex: "`virtual_pixel.gif`"
  - var: "`randomFileType`"
    desc: "A random file type."
    ex: "`audio`"
  - var: "`randomFileExt`"
    desc: "A random file extension."
    ex: "`mp3`"
  - var: "`randomCommonFileName`"
    desc: "A random commonly-used file name."
    ex: "`report.pdf`"
  - var: "`randomCommonFileType`"
    desc: "A random commonly-used file type."
    ex: "`image`"
  - var: "`randomCommonFileExt`"
    desc: "A random commonly-used file extension."
    ex: "`png`"
  - var: "`randomFilePath`"
    desc: "A random file path."
    ex: "`/usr/local/share/virtual_pixel.gif`"
  - var: "`randomDirectoryPath`"
    desc: "A random directory path."
    ex: "`/usr/local/share`"
  - var: "`randomMimeType`"
    desc: "A random MIME type."
    ex: "`application/json`"
{% endtable %}
<!-- vale on -->

## Commerce / Products

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: var
  - title: Description
    key: desc
  - title: Example
    key: ex
rows:
  - var: "`randomPrice`"
    desc: "A random price."
    ex: "`94.32`"
  - var: "`randomProduct`"
    desc: "A random product."
    ex: "`Pants`"
  - var: "`randomProductAdjective`"
    desc: "A random product adjective."
    ex: "`Refined`"
  - var: "`randomProductMaterial`"
    desc: "A random product material."
    ex: "`Cotton`"
  - var: "`randomProductName`"
    desc: "A random full product name."
    ex: "`Refined Cotton Pants`"
  - var: "`randomDepartment`"
    desc: "A random retail department."
    ex: "`Garden`"
{% endtable %}
<!-- vale on -->
