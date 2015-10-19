clilib
======

Command-line utilities library.


Command-line Arguments utilities
--------------------------------

Ported from [dart-lang/args](https://github.com/dart-lang/args)  
A command-line argument parsing library for Dart.

> Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
 for details. All rights reserved. Use of this source code is governed by a
 BSD-style license that can be found in the LICENSE file.

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


### Usage

```as3
import shell.Program;
import cli.args.*;

var parser:ArgParser = new ArgParser();
var results:ArgResults = parser.parse( Program.argv );
//etc.

```

### Misc.

We could also use [ArgumentsParser.as](https://code.google.com/p/maashaack/source/browse/packages/system_cli/trunk/src/system/cli/ArgumentsParser.as), it was working fine and even lighter and simpler.

But the idea is to standardise on the POSIX style options, the same way [Redtamarin](https://github.com/Corsaair/redtamarin) provide a POSIX library for C functions like `fopen()`, `getenv()`, etc. it was only logic to provide a library that enforce POSIX for command-line arguements.

Among many different libraries that parse command-line options [dart-lang/args](https://github.com/dart-lang/args) was chosen, a bit of an arbritary choice consisting
of me thinking this library is of good quality and a good opportunity to port Dart code to AS3 code.

### Info

This library is alpha quality, it's been ported quite fast and not fully tested.
It need a bit more real life testing with a couple of command-line tools and should be fine.
