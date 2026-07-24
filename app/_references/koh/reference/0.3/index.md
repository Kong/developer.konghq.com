---
title: CLI Documentation
---

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

## Commands

- [`collection`](/koh/reference/collection/{{page.release}}/): Manage collections
- [`document`](/koh/reference/document/{{page.release}}/): Manage API specifications
- [`environment`](/koh/reference/environment/{{page.release}}/): Manage environments
- [`import`](/koh/reference/import/{{page.release}}/): Import resources into a project
- [`request`](/koh/reference/request/{{page.release}}/): Manage requests within collections
- [`skills`](/koh/reference/skills/{{page.release}}/): Manage agent skills

## Subcommands

- [`collection list`](/koh/reference/collection_list/{{page.release}}/): List all collections in the project
- [`collection show`](/koh/reference/collection_show/{{page.release}}/): Show collection details
- [`collection create`](/koh/reference/collection_create/{{page.release}}/): Create a new empty collection
- [`collection update`](/koh/reference/collection_update/{{page.release}}/): Update a collection
- [`collection remove`](/koh/reference/collection_remove/{{page.release}}/): Remove a collection

## Subcommands

- [`document list`](/koh/reference/document_list/{{page.release}}/): List all documents in the project
- [`document show`](/koh/reference/document_show/{{page.release}}/): Show document details
- [`document remove`](/koh/reference/document_remove/{{page.release}}/): Remove a document
- [`document spec`](/koh/reference/document_spec/{{page.release}}/): Inspect specs within documents
- [`document spec show`](/koh/reference/document_spec_show/{{page.release}}/): Show the document spec
- [`document spec operation`](/koh/reference/document_spec_operation/{{page.release}}/): Inspect operations in a document spec
- [`document spec operation search`](/koh/reference/document_spec_operation_search/{{page.release}}/): Search operations in a document spec
- [`document spec operation list`](/koh/reference/document_spec_operation_list/{{page.release}}/): List operations in a document spec
- [`document spec operation show`](/koh/reference/document_spec_operation_show/{{page.release}}/): Show a single operation in a document spec

## Subcommands

- [`environment list`](/koh/reference/environment_list/{{page.release}}/): List all environments, or sub-environments when --environment is given
- [`environment show`](/koh/reference/environment_show/{{page.release}}/): Show environment details, or a sub-environment when --environment is given
- [`environment create`](/koh/reference/environment_create/{{page.release}}/): Create a new environment, or a sub-environment when --environment is given
- [`environment update`](/koh/reference/environment_update/{{page.release}}/): Update environment metadata, or a sub-environment when --environment is given
- [`environment remove`](/koh/reference/environment_remove/{{page.release}}/): Remove an environment, or a sub-environment when --environment is given

## Subcommands

- [`import oas`](/koh/reference/import_oas/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification (YAML or JSON)
- [`import oas collection`](/koh/reference/import_oas_collection/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification as a collection
- [`import oas document`](/koh/reference/import_oas_document/{{page.release}}/): Import an OpenAPI 3.x or Swagger 2.0 Specification as an Insomnia spec document
- [`import curl`](/koh/reference/import_curl/{{page.release}}/): Import a cURL command as a request

## Subcommands

- [`request list`](/koh/reference/request_list/{{page.release}}/): List requests, optionally scoped to a collection
- [`request show`](/koh/reference/request_show/{{page.release}}/): Show request details
- [`request create`](/koh/reference/request_create/{{page.release}}/): Create a new request
- [`request update`](/koh/reference/request_update/{{page.release}}/): Update a request
- [`request remove`](/koh/reference/request_remove/{{page.release}}/): Remove a request
- [`request run`](/koh/reference/request_run/{{page.release}}/): Run a request

## Subcommands

- [`skills install`](/koh/reference/skills_install/{{page.release}}/): Install bundled agent skill files

