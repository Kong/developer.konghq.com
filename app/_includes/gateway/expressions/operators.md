
An operator defines the desired comparison action to be performed on the field against the provided constant value. The operator always displays in the middle of the predicate, between the field and constant value.

The expressions language supports a rich set of operators that can be performed on various data types.

<!--vale off-->
{% table %}
columns:
  - title: Operator
    key: operator
  - title: Name
    key: name
  - title: Description
    key: description
rows:
  - operator: "`==`"
    name: Equals
    description: "Field value is equal to the constant value."
  - operator: "`!=`"
    name: Not equals
    description: "Field value does not equal the constant value."
  - operator: "`~`"
    name: Regex match
    description: "Field value matches regex."
  - operator: "`^=`"
    name: Prefix match
    description: "Field value starts with the constant value."
  - operator: "`=^`"
    name: Postfix match
    description: "Field value ends with the constant value."
  - operator: "`>=`"
    name: Greater than or equal
    description: "Field value is greater than or equal to the constant value."
  - operator: "`>`"
    name: Greater than
    description: "Field value is greater than the constant value."
  - operator: "`<=`"
    name: Less than or equal
    description: "Field value is less than or equal to the constant value."
  - operator: "`<`"
    name: Less than
    description: "Field value is less than the constant value."
  - operator: "`in`"
    name: In
    description: |
      Field value is inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. 
      <br><br>
      For example, `net.src.ip in 192.168.0.0/24` only returns `true` if the value of `net.src.ip` is within `192.168.0.0/24`.
  - operator: "`not in`"
    name: Not in
    description: |
      Field value is not inside the constant value. This operator is used with `IpAddr` and `IpCidr` types to perform an efficient IP list check. 
      <br><br>
      For example, `net.src.ip in 192.168.0.0/24` only returns `true` if the value of `net.src.ip` is within `192.168.0.0/24`.
  - operator: "`contains`"
    name: Contains
    description: |
      Field value contains the constant value. This operator is used to check the existence of a string inside another string. 
      <br><br>
      For example, `http.header contains \"foo\"` returns `true` if `foo` can be found anywhere inside `http.header`. This will match an `HTTP.header` that looks like `x-foo`, `x-abc-foo`, or `x-fooy`, for example.
  - operator: "`&&`"
    name: And
    description: "Returns `true` if **both** expressions on the left and right sides evaluate to `true`."
  - operator: "`||`"
    name: Or
    description: "Returns `true` if **any** expressions on the left or right side evaluate to `true`."
  - operator: "`(Expression)`"
    name: Parenthesis
    description: "Groups expressions together to be evaluated first."
  - operator: "`!`"
    name: Not
    description: |
      Negates the result of a parenthesized expression. 
      <br><br>
      The `!` operator can only be used with parenthesized expression like `!(foo == 1)`, it **cannot** be used with a bare predicate like `! foo == 1`."
{% endtable %}
<!--vale on-->