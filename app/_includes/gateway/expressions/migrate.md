The plugin expression language changed between 3.14 and 3.15.
In {{site.base_gateway}} 3.14, the feature was in beta and used ATC (Abstract Tree Classifier) syntax for plugin conditions. 
{{site.base_gateway}} 3.15 uses [CEL (Common Expression Language)](/gateway/plugins/expressions/), which isn't backwards-compatible.

Any conditional expression that worked in 3.14 will need to be rewritten for 3.15.
The main syntax changes are:

* Prefix matching: `^=` → `starts_with()`. For example, `http.path ^= "/api"` becomes `http.path.starts_with("/api")`.
* Suffix matching: `=^` → `ends_with()`. For example, `http.path =^ ".json"` becomes `http.path.ends_with(".json")`.
* Regex matching: `~` → `matches()`. For example, `http.path ~ r#"^/api/v[0-9]+"#` becomes `http.path.matches("^/api/v[0-9]+")`.
* The `http.path.segments.<index>` fields are replaced by `http.path_segments` (a list).
* Header and query fields now return `null` when absent (instead of an empty string), so null checks may be needed.

For the 3.14 beta reference, see [Conditional expressions for plugins in 3.14](/gateway/plugins/expressions-314/).