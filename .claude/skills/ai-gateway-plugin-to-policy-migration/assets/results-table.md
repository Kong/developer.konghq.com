# Templates

## Testing plan (Gate 1)

Written for the user, in plain language. No tables, no jargon, no unexplained option names.

```
## What the policy does
<2-3 sentences: what it adds or changes, and why someone would want it.>

Settings:
- **`name`**: <what it controls, in one line>

## What I'd test
1. **<Short name>:** <what I will do, and what result I expect.>
2. ...
(4 to 6 checks. The first is always a baseline with no policy.)

## What I'd leave out
- <Item>: <why>. It will be listed as "not tested" and will not appear on the page.

## What I would not port from the plugin page
- <Item>: <why, in one line>

## Options
- Minimal: checks <n, n, n>. Covers <what>.
- Full: all checks.
Recommendation: <one of them, and why>.

## Questions
1. <Direct question for the user>
```

## Option inventory (working notes and final summary only)

| Field / mode / claim | Source (schema or plugin page) | Gateway-only dependency? | Planned test |
|---|---|---|---|
| `config.<field>` | schema | no | each value, 8+ repeats if probabilistic |

## Results table (Gate 3)

| Option | Scope | Result | Evidence (command / log / response) | Status |
|---|---|---|---|---|
| `config.<field>` = `<value>` | Model | observed behavior | exact request and response | verified / contradicted / untested |

Cover: control with no policy, each parameter and enum value, each scope in `scopes.json` you could set up, streaming and non-streaming, real provider, policy interaction, upstream-traffic details (Host, TLS server name, path, body) where relevant.

## Final summary

1. What changed (files).
2. Verified behavior (one line per item, pointing to the results table).
3. Contradicted claims removed or fixed.
4. Untested items (not on the page).
5. Suspected bugs, each with repro and a draft engineering message (see below).
6. Cleanup confirmation: collections listed, nothing with the prefix remains, mock stopped, CA bundle restored, data plane `STATE_IN_SYNC`.
7. Open editorial questions.

## Draft engineering message (question form)

> Environment: <gateway, runtime version>
> Setup: <entities and policy config>
> Steps: <requests>
> Observed: <result>
> Expected: <result>
> Question: <what you need to know>
