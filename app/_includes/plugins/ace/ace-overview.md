The Access Control Enforcement (ACE) plugin manages developer access control to APIs published with Dev Portal.

You can use the ACE plugin as an alternative to the {{site.konnect_short_name}} application auth (KAA) plugin to link APIs to a Gateway instead of linking APIs to a Gateway Service. 
Unlike the KAA plugin, the ACE plugin can link to control planes to configure access control and create API package operations for Gateway Services.
API packages use the ACE plugin to manage developer access control to APIs. 

The ACE plugin runs *after* all other [authentication plugins](/plugins/?category=authentication) run. 
For example, if you have [Key Authentication](/plugins/key-auth/) configured and it rejects a request, the ACE plugin *will not* run. 

To allow for multiple authentication plugins, each one must set the [`config.anonymous`](/plugins/ace/reference/#schema--config-anonymous) plugin configuration. 
Additionally, the choice to allow or reject an `anonymous` result after all authentication plugins have run needs to be controlled as described in [using multiple authentication methods](/gateway/authentication/#using-multiple-authentication-methods).