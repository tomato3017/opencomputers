Application Conf
=====

This package includes the default application.conf file for opencomputers and a parser for that file. Update /etc/application.conf with your own application.conf if you have updated it

To reference values in the application.conf in your script simply use the following example

```
local conf = require("applicationconf")
print(conf.opencomputers.computer.threads) -- prints 4
```