For this tutorial, you’ll need a Dev Portal pre-configured. These settings are essential for Dev Portal to function, but configuring them isn’t the focus of this guide. If you don't have these settings already configured, follow these steps to pre-configure them:

1. Create a Dev Portal and add a page to display your published APIs:

   ```hcl
   echo '
   resource "konnect_portal" "my_portal" {
     authentication_enabled               = false
     auto_approve_applications            = false
     auto_approve_developers              = true
     default_api_visibility               = "public"
     default_page_visibility              = "public"
     description                          = "...my_description..."
     display_name                         = "...my_display_name..."
     force_destroy                        = "false"
     name         = "My Portal"
     rbac_enabled = true
   }
   resource "konnect_portal_page" "my_portalpage" {
     portal_id   = konnect_portal.my_portal.id
     title       = "My Page"
     slug        = "/apis"
     description = "A custom page about developer portals"
     visibility  = "public"
     status      = "published"

     content = <<-MD
     # Welcome to My Dev Portal

     Explore the available APIs below:

     ::apis-list
     ---
     persist-page-number: true
     cta-text: "View APIs"
     ---
     MD
   }
   ' >> main.tf
   ```

1. Create all of the defined resources using Terraform:

   ```bash
   terraform apply -auto-approve
   ```