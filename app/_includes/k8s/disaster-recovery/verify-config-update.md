To check that the control plane distributes new configuration, use a temporary path that the `dr-check` Route doesn't already match, such as `/dr-verify`.
Route paths are prefixes, so `/dr-check` already matches `/dr-check-recovered`, and a request to that path succeeds before any change.

1. Send a request to `/dr-verify` through the replacement data plane, and make sure that it returns `404`.
1. Add the path to the Route {{include.owner}}.
1. Send the request again, and make sure that it returns the same application response as `/dr-check`.
1. Remove the path, and make sure that the request returns `404` again.
