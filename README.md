# Overview

This is an extremely fast, allocationless, thread-safe*, betterC, structured logging library that supports custom log sinks.

(* Currently only on Posix since I need to setup a dev env for Windows. Also maybe not even on Posix since I haven't properly tested it yet.)

## Features

* Thread-Safe (see disclaimer)
* Allocationless (except for whatever libc does internally)
* Easy to use
* Written with -betterC in mind
* Supports custom logging sinks
  * Provides a Console sink
  * Provides a File sink
  * Provides a Filter sink to wrap around other sinks
* Structured (built-in sinks output as JSON)
* Helper function to output JSON into an output sink

## Quick Start

Add this library via dub/meson/your preferred method.

```d
import libbc.log;

struct Client
{
    string ip;
    ushort port;
}

void main()
{
    // Logger is not copyable, so make it global/put it on the heap.
    Logger!(
        IsShared.no, // Or .yes for a thread-safe logger.
        Sink!("file", FileSink),
        Sink!("console", ConsoleSink)
    ) logger;
    logger.file.open("log.log"); // File loggers have to be opened first.

    logger.trace("This is a trace");
    logger.debug_("Debug This Bug!");

    logger.info("This one has fields!", field!"service"("login"), field!"client"(Client("1.1.1.1", 420)));

    logger.warning("404 Life not found");
    logger.error("Not enough cheese");
    logger.fatal("Dog went 5 seconds without attention");
}
```

Produces:

```json
{"level": "trace", "message": "This is a trace", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 255, "timestamp": 1636142080}
{"level": "debug_", "message": "Debug This Bug!", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 256, "timestamp": 1636142080}
{"level": "info", "message": "This one has fields!", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 258, "timestamp": 1636142080, "service": "login", "client": {"ip": "1.1.1.1", "port": 420}}
{"level": "warning", "message": "404 Life not found", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 260, "timestamp": 1636142080}
{"level": "error", "message": "Not enough cheese", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 261, "timestamp": 1636142080}
{"level": "fatal", "message": "Dog went 5 seconds without attention", "file": "source/libbc/log/core.d", "func": "libbc.log.core.__unittest_L237_C1", "line": 262, "timestamp": 1636142080}
```

## Filtering by log level

Simply wrap any sinks inside of `FilterByLogLevelSink`:

```d
void main()
{
    Logger!(
        IsShared.no,
        Sink!("console", FilterByLogLevelSink!ConsoleSink)
    ) logger;

    logger.console.minLogLevel = LogLevel.debug_;
    logger.console.maxLogLevel = LogLevel.warning;
    // Use logger.console.sink to access the underlying sink if needed.

    logger.trace("This won't show up");
    logger.fatal("Neither will this");
    logger.info("But this will");
}
```

## Performance

As is custom with benchmarks, take everything with a grain of salt.

There are currently two tests:

* hello_world - A simple `log.info("hello world")`
* 6_fields - Prints out 6 fields, all being different types for JSON serialisation

Across three sinks:

* console - Uses printf
* null - Performs serialisation, but doesn't output it anywhere
* file - Outputs to a file

### Result set 1 - Intel(R) Celeron(R) CPU N3350 @ 1.10GHz

Units: **ns = nano seconds** and **us = micro seconds**.

| test+sink           | iterations | ns/op | us/op | ns/total   | us/total | secs/total  |
|---------------------|------------|-------|-------|------------|----------|-------------|
| console hello_world | 100000     | 41897 | 41    | 4189774378 | 4142458  | 4.189774378 |
| null hello_world    | 100000     | 283   | 0     | 28396792   | 579      | 0.028396792 |
| file hello_world    | 100000     | 2482  | 2     | 248276451  | 297487   | 0.248276451 |
| console 6_fields    | 100000     | 90012 | 89    | 9001273208 | 8962859  | 9.001273208 |
| null 6_fields       | 100000     | 573   | 0     | 57367364   | 4149     | 0.057367364 |
| file 6_fields       | 100000     | 9041  | 8     | 904163987  | 864092   | 0.904163987 |

### Result set 2 - Intel(R) Core(TM) i5-7600K CPU @ 3.80GHz

| test+sink           | iterations | ns/op | us/op | ns/total   | us/total | secs/total  |
|---------------------|------------|-------|-------|------------|----------|-------------|
| console hello_world | 100000     | 3968  | 3     | 398628984  | 321941   | 0.398628984 |
| null hello_world    | 100000     | 63    | 0     | 6342413    | 4        | 0.006342413 |
| file hello_world    | 100000     | 603   | 2     | 60306126   | 11314    | 0.060306126 |
| console 6_fields    | 100000     | 9790  | 9     | 979082440  | 946392   | 0.97908244  |
| null 6_fields       | 100000     | 144   | 0     | 14465363   | 88       | 0.014465363 |
| file 6_fields       | 100000     | 3131  | 2     | 313126877  | 229199   | 0.313126877 |

## TODO

[ ] Make Windows thread-safe

[ ] Add more sinks

[ ] Add threading tests

[ ] Add a log rotater sink

[ ] ???

[x] profit
