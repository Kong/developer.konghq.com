---
#
#  WARNING: this file was auto-generated by a script.
#  DO NOT edit this file directly. Instead, send a pull request to change
#  the files in https://github.com/Kong/kong/tree/master/autodoc/cli
#
title: CLI Reference
source_url: https://github.com/Kong/kong/tree/master/autodoc/cli
description: The Kong CLI allows you to start, stop, and manage your Kong instances. 
---

The provided CLI (*Command Line Interface*) allows you to start, stop, and
manage your Kong instances. The CLI manages your local node (as in, on the
current machine).

If you haven't yet, we recommend you read the [configuration reference][configuration-reference].

## Global flags

All commands take a set of special, optional flags as arguments:

* `--help`: print the command's help message
* `--v`: enable verbose mode
* `--vv`: enable debug mode (noisy)

## Available commands


### kong check

```
Usage: kong check <conf>

Check the validity of a given Kong configuration file.

<conf> (default /etc/kong/kong.conf) configuration file

```

---


### kong config

```
Usage: kong config COMMAND [OPTIONS]

Use declarative configuration files with Kong.

The available commands are:
  init [<file>]                       Generate an example config file to
                                      get you started. If a filename
                                      is not given, ./kong.yml is used
                                      by default.

  db_import <file>                    Import a declarative config file into
                                      the Kong database.

  db_export [<file>]                  Export the Kong database into a
                                      declarative config file. If a filename
                                      is not given, ./kong.yml is used
                                      by default.

  parse <file>                        Parse a declarative config file (check
                                      its syntax) but do not load it into Kong.

Options:
 -c,--conf        (optional string)   Configuration file.
 -p,--prefix      (optional string)   Override prefix directory.

```

---


### kong debug

```
Usage: kong debug COMMAND [OPTIONS]

Invoke various debugging features in Kong.

The available commands are:

  For the endpoint in kong/api/routes/debug.lua,

  profiling cpu <start|stop|status>     Generate the raw data of Lua-land CPU
                                        flamegraph.

    --mode      (optional string default "time")
                                        The mode of CPU profiling, `time` means
                                        time-based profiling, `instruction`
                                        means instruction-counter-based
                                        profiling.

    --step      (optional number)       The initial value of the instruction
                                        counter. A sample will be taken when the
                                        counter goes to zero.
                                        (only for mode=instruction)

    --interval  (optional number)       Sampling interval in microseconds.
                                        (only for mode=time)

    --timeout (optional number)         Profiling will be stopped automatically
                                        after the timeout (in seconds).
                                        default: 10

  profiling memory <start|stop|status>  Generating the Lua GC heap memory
                                        tracing data (on-the-fly tracing).

    --stack_depth (optional number)     The maximum depth of the Lua stack.

    --timeout (optional number)         Profiling will be stopped automatically
                                        after the timeout (in seconds).
                                        default: 10

  profiling gc-snapshot                 Generate a Lua GC heap snapshot.

    --timeout (optional number)         Profiling will be stopped automatically
                                        after the timeout (in seconds).
                                        default: 120

  log_level set --level <log_level>     Set the logging level.
                                        It cannot work while not using a
                                        database because it needs to be
                                        protected by RBAC and RBAC is not
                                        available in DB-less.

    --level (optional string)           It can be one of the following: debug,
                                        info, notice, warn, error, crit, alert,
                                        or emerg.

    --timeout (optional number)         The log level will be restored to the
                                        original level after the timeout (in
                                        seconds).
                                        default: 60

  log_level get                         Get the logging level.


Options:
 --pid            (optional number)     The worker’s PID for profiling.

 -f                                     Follow mode for certain commands, such
                                        as 'profiling {cpu|memory} status'.
                                        It continuously checks the status until
                                        it completes.

 -c,--conf        (optional string)     Configuration file.
 -p,--prefix      (optional string)     Override prefix directory.


EXIT CODES
  Various error codes and their associated messages may be returned by this
  command during error situations.

 `0` - Success. The requested operation completed successfully.

 `1` - Error. The requested operation failed. An error message is available in
       the command output.

 `2` - In progress. The profiling is still in progress.
       The following commands make use of this return value:
       - kong debug profiling cpu start
       - kong debug profiling memory start
       - kong debug profiling gc-snapshot


```

---


### kong health

```
Usage: kong health [OPTIONS]

Check if the necessary services are running for this node.

Options:
 -p,--prefix      (optional string) prefix at which Kong should be running

```

---


### kong hybrid

```
Usage: kong hybrid COMMAND [OPTIONS]

Hybrid mode utilities for Kong.

The available commands are:
  gen_cert [<cert> <key>]           Generate a certificate/key pair that is suitable
                                    for use in hybrid mode deployment.
                                    Cert and key will be written to
                                    './cluster.crt' and './cluster.key' inside
                                    the current directory unless filenames are given.

Options:
 -d,--days        (optional number) Override certificate validity duration.
                                    Default: 1095 days (3 years)

```

---


### kong migrations

```
Usage: kong migrations COMMAND [OPTIONS]

Manage database schema migrations.

The available commands are:
  bootstrap                         Bootstrap the database and run all
                                    migrations.

  up                                Run any new migrations.

  finish                            Finish running any pending migrations after
                                    'up'.

  list                              List executed migrations.

  reset                             Reset the database. The `reset` command erases all of the data in Kong's database and deletes all of the schemas.

  migrate-community-to-enterprise   Migrates CE entities to EE on the default
                                    workspace

  upgrade-workspace-table           Outputs a script to be run on the db to upgrade
                                    the entity for 2.x workspaces implementation


  reinitialize-workspace-entity-counters  Resets the entity counters from the
                                          database entities.
  status                            Dump the database migration status in JSON format

Options:
 -y,--yes                           Assume "yes" to prompts and run
                                    non-interactively.

 -q,--quiet                         Suppress all output.

 -f,--force                         Run migrations even if database reports
                                    as already executed.

                                    With 'migrate-community-to-enterprise' it
                                    disables the workspace entities check.

 --db-timeout     (optional number) Timeout, in seconds, for all database
                                    operations.


 --lock-timeout   (default 60)      Timeout, in seconds, for nodes waiting on
                                    the leader node to finish running
                                    migrations.

 -c,--conf        (optional string) Configuration file.

 -p,--prefix      (optional string)   Override prefix directory.


```

---


### kong prepare

This command prepares the Kong prefix folder, with its sub-folders and files.

```
Usage: kong prepare [OPTIONS]

Prepare the Kong prefix in the configured prefix directory. This command can
be used to start Kong from the nginx binary without using the 'kong start'
command.

Example usage:
 kong migrations up
 kong prepare -p /usr/local/kong -c kong.conf
 nginx -p /usr/local/kong -c /usr/local/kong/nginx.conf

Options:
 -c,--conf       (optional string) configuration file
 -p,--prefix     (optional string) override prefix directory
 --nginx-conf    (optional string) custom Nginx configuration template

```

---


### kong quit

```
Usage: kong quit [OPTIONS]

Gracefully quit a running Kong node (Nginx and other
configured services) in given prefix directory.

This command sends a SIGQUIT signal to Nginx, meaning all
requests will finish processing before shutting down.
If the timeout delay is reached, the node will be forcefully
stopped (SIGTERM).

Options:
 -p,--prefix      (optional string) prefix Kong is running at
 -t,--timeout     (default 10) timeout before forced shutdown
 -w,--wait        (default 0) wait time before initiating the shutdown

```

---


### kong reload

```
Usage: kong reload [OPTIONS]

Reload a Kong node (and start other configured services
if necessary) in given prefix directory.

This command sends a HUP signal to Nginx, which will spawn
new workers (taking configuration changes into account),
and stop the old ones when they have finished processing
current requests.

Options:
 -c,--conf                 (optional string) configuration file
 -p,--prefix               (optional string) prefix Kong is running at
 --nginx-conf              (optional string) custom Nginx configuration template
 --nginx-conf-flags        (optional string) flags that can be used to control
                                             how Nginx configuration templates are rendered

```

---


### kong restart

```
Usage: kong restart [OPTIONS]

Restart a Kong node (and other configured services like Serf)
in the given prefix directory.

This command is equivalent to doing both 'kong stop' and
'kong start'.

Options:
 -c,--conf                 (optional string)   configuration file
 -p,--prefix               (optional string)   prefix at which Kong should be running
 --nginx-conf              (optional string)   custom Nginx configuration template
 --run-migrations          (optional boolean)  optionally run migrations on the DB
 --db-timeout              (optional number)
 --lock-timeout            (default 60)
 --nginx-conf-flags        (optional string)   flags that can be used to control
                                               how Nginx configuration templates are rendered

```

---


### kong runner

```
Usage: kong runner file.lua [args]

Execute a lua file in a kong node. The `kong` variable is available to
reach the DAO, PDK, etc. The variable `args` can be used to access all
arguments (args[1] being the lua filename being run).

```

---


### kong start

```
Usage: kong start [OPTIONS]

Start Kong (Nginx and other configured services) in the configured
prefix directory.

Options:
 -c,--conf                 (optional string)   Configuration file.

 -p,--prefix               (optional string)   Override prefix directory.

 --nginx-conf              (optional string)   Custom Nginx configuration template.

 --run-migrations          (optional boolean)  Run migrations before starting.

 --db-timeout              (optional number)   Timeout, in seconds, for all database
                                               operations.

 --lock-timeout            (default 60)        When --run-migrations is enabled, timeout,
                                               in seconds, for nodes waiting on the
                                               leader node to finish running migrations.

 --nginx-conf-flags        (optional string)   Flags that can be used to control
                                               how Nginx configuration templates are rendered

```

---


### kong stop

```
Usage: kong stop [OPTIONS]

Stop a running Kong node (Nginx and other configured services) in given
prefix directory.

This command sends a SIGTERM signal to Nginx.

Options:
 -p,--prefix      (optional string) prefix Kong is running at

```

---


### kong vault

```
Usage: kong vault COMMAND [OPTIONS]

Vault utilities for Kong.

Example usage:
 TEST=hello kong vault get env/test

The available commands are:
  get <reference>  Retrieves a value for <reference>

Options:
 -c,--conf    (optional string)  configuration file
 -p,--prefix  (optional string)  override prefix directory

```

---


### kong version

```
Usage: kong version [OPTIONS]

Print Kong's version. With the -a option, will print
the version of all underlying dependencies.

Options:
 -a,--all         get version of all dependencies

```

---


[configuration-reference]: /gateway/configuration/
