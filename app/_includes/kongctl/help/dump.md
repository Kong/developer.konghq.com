```bash
Usage:
  kongctl dump [flags]
  kongctl dump [command]

Aliases:
  dump, d, D

Examples:
  # Export all portals as Terraform import blocks to stdout
  kongctl dump tf-import --resources=portal
  
  # Export all portals and their child resources (documents, specifications, pages, settings)
  kongctl dump tf-import --resources=portal --include-child-resources
  
  # Export all portals as Terraform import blocks to a file
  kongctl dump tf-import --resources=portal --output-file=portals.tf
  
  # Export all APIs with their child resources and include debug logging
  kongctl dump tf-import --resources=api --include-child-resources --log-level=debug
  
  # Export declarative configuration with a default namespace
  kongctl dump declarative --resources=portal,api --default-namespace=team-alpha

Available Commands:
  declarative Export resources as kongctl declarative configuration
  tf-import   Export resources as Terraform import blocks

Flags:
  -h, --help   help for dump

```