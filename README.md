# Overview

This is an allocationless, thread-safe*, betterC, structured logging library that supports custom log sinks.

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

Add this library via dub/your preferred method (I'll be Mesonifying this library soon).

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

## TODO

[ ] Make Windows thread-safe
[ ] Add more sinks
[ ] Add threading tests
[ ] Add a log rotater sink
[ ] ???
[x] profit
