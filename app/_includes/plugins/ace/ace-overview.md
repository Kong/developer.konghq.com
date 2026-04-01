The Access Control Enforcement (ACE) plugin manages developer access control to APIs published with Dev Portal.

Previously, when you created an API catalog in Dev Portal and linked the APIs to a Gateway Service, {{site.konnect_short_name}} would automatically apply the {{site.konnect_short_name}} application auth (KAA) plugin. 
API packages use the ACE plugin instead to manage developer access control to APIs. Unlike the KAA plugin, the ACE plugin can link to control planes to configure access control and create operations for Gateway Services.

The ACE plugin runs *after* all other [authentication plugins](/plugins/?category=authentication) run. 
For example, if you have [Key Authentication](/plugins/key-auth/) configured and it rejects a request, the ACE plugin *will not* run. 

To allow for multiple authentication plugins, each one must set the [`config.anonymous`](/plugins/ace/reference/#schema--config-anonymous) plugin configuration. 
Additionally, the choice to allow or reject an `anonymous` result after all authentication plugins have run needs to be controlled as described in [using multiple authentication methods](/gateway/authentication/#using-multiple-authentication-methods).