Types define what you can use for a predicate's field and constant value. Expressions language is strongly typed. Operations are only performed
if such an operation makes sense in regard to the actual type of field and constant.

Type conversion at runtime is not supported, either explicitly or implicitly. Types
are always known at the time a route is parsed. An error is returned
if the operator cannot be performed on the provided field and constant.

The expressions language currently supports the following types:

<!-- vale off -->

{% feature_table %}
item_title: Object
columns:
  - title: Description
    key: description
  - title: Field type
    key: field_type
  - title: Constant type
    key: constant_type
features:
  - title: |
      `String`
    description: |
      A string value, always in valid UTF-8. They can be defined with string literal that looks like `"content"`. You can also use the following escape sequences:
      * `\n`: Newline character
      * `\r`: Carriage return character
      * `\t`: Horizontal tab character
      * `\\`: The `\` character
      * `\"`: The `"` character
      <br><br>
       
      In addition, expressions support raw string literals, like `r#"content"#`. This feature is useful if you want to write a regex and repeated escaping becomes tedious to deal with.
      <br><br>
      For example, if you want to match `http.path` against `/\d+\-\d+` using the regex `~` operator, the predicate will be written as the following with string literals:
      <br>
      ```text
      http.path ~ "/\\d+\\-\\d+"
      ```
      <br>
      With raw string literals, you can write:
      <br>
      ```text
      http.path ~ r#"/\d+\-\d+"#
      ```
    field_type: true
    constant_type: true
  - title: |
      `IpCidr`
    description: |
      Range of IP addresses in CIDR format. Can be either IPv4 (`net.src.ip in 192.168.1.0/24`) or IPv6 (`net.src.ip in fd00::/8`). The expressions parser rejects any CIDR literal where the host portion contains any non-zero bits. This means that `192.168.0.1/24` won't pass the parser check because the intention of the author is unclear.
    field_type: false
    constant_type: true
  - title: |
      `IpAddr`
    description: |
      A single IP address in IPv4 Dot-decimal notation (`net.src.ip == 192.168.1.1`), or the standard IPv6 Address Format (`net.src.ip == fd00::1`). Can be either IPv4 or IPv6.
    field_type: true
    constant_type: true
  - title: |
      `Int`
    description: |
      A 64-bit signed integer. There is only one integer type in expressions. All integers are signed 64-bit integers. Integer literals can be written as `12345`, `-12345`, or in hexadecimal format, such as `0xab12ff`, or in octet format like `0751`.
    field_type: true
    constant_type: true
  - title: |
      `Regex`
    description: |
      Regex are written as `String` literals, but they are parsed when the `~` regex operator is present and checked for validity according to the [Rust `regex` crate syntax](https://docs.rs/regex/latest/regex/#syntax). For example, in the following predicate, the constant is parsed as a regex: `http.path ~ r#"/foo/bar/.+"#`
    field_type: false
    constant_type: true
{% endfeature_table %}

<!--vale on-->

In addition, the expressions router also supports one composite type, `Array`. Array types are written as `Type[]`.
For example: `String[]`, `Int[]`. Currently, arrays can only be present in field values. They are used in
case one field could contain multiple values. For example, `http.headers.x` or `http.queries.x`.
