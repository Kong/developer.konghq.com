<!---shared with AI Gateway logging Policies: http-log, file-log, syslog, tcp-log, udp-log, loggly, kafka-log, solace-log --->

This Policy logs request and response data for each proxied request.

The {{site.ai_gateway}} process error file is the Nginx error file. You can find it at the following path:

`$PREFIX/logs/error.log`

Configure the [prefix](/gateway/configuration/#prefix) in `kong.conf`.
