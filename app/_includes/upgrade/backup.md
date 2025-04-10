Always back up your database or declarative configuration files before an upgrade.
The `kong migrations` commands used during upgrade and database migration are not reversible.

There are two main types of backup for {{site.base_gateway}} entities:
* **Database backup**: PostgreSQL has native exporting and importing tools that are reliable and performant, and that ensure consistency when backing up or restoring data. If you're running {{site.base_gateway}} in Traditional or Hybrid mode, you should always take a database-native backup.
* **Declarative backup**: Kong ships two declarative backup tools: [decK](/deck/) and the [Kong CLI](/gateway/cli/reference/), which support managing {{site.base_gateway}} entities in the declarative format.
For Traditional and Hybrid mode deployments, use these tools to create secondary backups. For DB-less mode deployments, use the Kong CLI and manually manage declarative configuration files.

We highly recommend backing up your data using both methods if possible, as this offers you recovery flexibility. 

The database-native tools are robust and can restore data instantly compared to the declarative tools. 
In case of data corruption, try to do a database-level restore first. 
Otherwise, bootstrap a new database and use declarative tools to restore configuration from backup files.

Review the [Backup and restore](/gateway/upgrade/backup-and-restore/) guide to 
prepare backups of your configuration.
If you run into any issues and need to roll back, you can also reference that guide to restore your old data store.
