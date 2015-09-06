clilib
======

Command-line utilities library.


Args Parser
-----------

Parses raw command-line arguments into a set of options and values.

This library supports GNU and POSIX style options.

example

```
--mode            The compiler configuration
                  [debug, release]

--out=<path>      The output path
--[no-]verbose    Show additional diagnostic info
--arch            The architecture to compile for
      [arm]       ARM Holding 32-bit chip
      [ia32]      Intel x86
```

