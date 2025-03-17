## Running {{site.base_gateway}} as a non-root user

When {{site.base_gateway}} is installed, the installation process creates the user group `kong`. Users that belong to the `kong` group can perform {{site.base_gateway}} actions. Adding your user to that user group will allow you to execute {{site.base_gateway}} commands on the system.

{:.warning}
> **Warning:** The Nginx master process needs to run as `root` for Nginx to execute certain actions (for example, to listen on the privileged port 80).
> <br><br>
> Although running Kong as the `kong` user and group does provide more security, we advise that a system and network administration evaluation be performed before making this decision. Otherwise, Kong nodes might become unavailable due to insufficient permissions to execute privileged system calls in the operating system.



You can check the permissions and ownership of the {{site.base_gateway}} in Linux like this: 

`ls -l /usr/local/kong`

Which will return a list of subdirectories that contain a prefix like this: 
`drwxrwxr-x 2 kong kong`

The two `kong` values mean that the directory is owned by the user `kong` and the group `kong`. 

To make an existing user part of the `kong` group, you can run this command: 

`usermod -aG kong $USER`

To view existing groups associated with the user, run: 

`groups $USER`


### Nginx

In {{site.base_gateway}}, the Nginx master process runs at the `root` level so that Nginx can execute actions even if {{site.base_gateway}} is running as a non-root user. This is important when building containers.

