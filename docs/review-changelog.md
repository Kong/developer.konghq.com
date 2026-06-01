# Reviewing the Gateway changelog

The Gateway (GW) team requests changelog reviews in the `#docs` Slack channel. They flag the level of urgency in the changelog. We share ownership of this process as a team.

## Process for reviewing the changelog and updating the docs

1. The GW team posts a `kong-ee` PR in `#docs` requesting a changelog review.
1. Make suggestions on the changelog in the `kong-ee` PR. Check for grammar issues and duplicate information.
1. Once the release is published and announced in `#team-gateway`, run the [GitHub Action](https://github.com/Kong/developer.konghq.com/actions/workflows/generate-gateway-plugins-changelogs.yml) to open a docs PR.
1. Double check that the image is up and tagged on Docker: https://hub.docker.com/r/kong/kong-gateway/tags
1. Merge the docs PR with the changelog updates.
