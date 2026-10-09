# KSAI test file: output blocks

Temporary file to check that the "Output blocks" review rule runs. Do not merge. The `_ksai-test` directory is not a Jekyll collection, so it isn't published.

## Violation

The following block shows only command output, so it should end with `{:.no-copy-code}`. It doesn't, so KSAI should flag it.

```sh
HTTP/1.1 200 OK
Content-Type: application/json
Connection: keep-alive

{"message": "pong"}
```

## Control: command

The following block is a command the reader runs, so KSAI should not flag it.

```sh
curl -i http://localhost:8000/ping
```

## Control: marked output

The following output block is marked correctly, so KSAI should not flag it.

```sh
HTTP/1.1 200 OK
```
{:.no-copy-code}

## Control: marked output with an extra class

The following output block has `.no-copy-code` plus another class, so KSAI should not flag it.

```sh
HTTP/1.1 200 OK
Content-Type: application/json
```
{:.no-copy-code .collapsible}
