There are a few key concepts to understand for linting with {{ include.tool }}:

- **Rules** define selectors, functions and the failure severity to apply to the provided file.
- **Selectors** define a filter to apply to the input file which selects the objects to validate. Selectors are specified in the `given` keyword on a Rule. Selectors are expressed using JSONPath syntax.
- **Functions** accept the filtered values and perform a validation returning information when there are violations.
- **Rulesets** are collections of Rules.
