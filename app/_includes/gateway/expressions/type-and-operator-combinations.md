Depending on the field type, only certain content types and operators are supported. 

<!--vale off-->
{% table %}
columns:
  - title: Field type
    key: field
  - title: Supported content types and their supported operators
    key: operators
rows:
  - field: "`String`"
    operators: |
      * `String`: `==`, `!=`, `~`, `^=`, `=^`, `contains`
      * `Regex`: `~`
  - field: "`IpAddr`"
    operators: |
      * `IpCidr`: `in`, `not in`
      * `IpAddr`: `==`
  - field: "`Int`"
    operators: |
      * `Int`: `==`, `!=`, `>=`, `>`, `<=`, `<`
  - field: "`Expression`"
    operators: |
      * `Regex`: `&&`, `||`
{% endtable %}
<!--vale on-->