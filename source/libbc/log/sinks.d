module libbc.log.sinks;

import libbc.log.core, core.stdc.stdio, core.stdc.time;

struct ConsoleSink
{
    void log(Fields...)(
        LogLevel level,
        string message,
        string file,
        string func,
        size_t line,
        time_t timestamp,
        Fields fields
    )
    {
        static struct PrintfRange
        {
            @nogc nothrow 
            void put(const char[] str)
            {
                printf("%.*s", cast(int)str.length, str.ptr);
            }
        }
        PrintfRange r;
        jsonToOutputSink(r,
            field!"level"(level),
            field!"message"(message),
            field!"file"(file),
            field!"func"(func),
            field!"line"(line),
            field!"timestamp"(timestamp),
            fields
        );
        printf("\n");
    }
}

struct FileSink
{
    @disable this(this){}

    FILE* file;

    ~this()
    {
        if(this.file)
            fclose(file);
    }

    bool open(const char[] file)
    {
        this.file = fopen(file.ptr, "w");
        return this.file !is null;
    }

    void log(Fields...)(
        LogLevel level,
        string message,
        string file,
        string func,
        size_t line,
        time_t timestamp,
        Fields fields
    )
    {
        if(!this.file)
            return;

        static struct FileRange
        {
            FILE* f;

            @nogc nothrow 
            void put(const char[] str)
            {
                fwrite(str.ptr, str.length, 1, f);
            }
        }
        auto r = FileRange(this.file);
        jsonToOutputSink(r,
            field!"level"(level),
            field!"message"(message),
            field!"file"(file),
            field!"func"(func),
            field!"line"(line),
            field!"timestamp"(timestamp),
            fields
        );
        fwrite("\n".ptr, 1, 1, this.file);
    }
}

struct FilterByLogLevelSink(SinkT)
{
    SinkT sink;
    LogLevel minLogLevel = LogLevel.trace;
    LogLevel maxLogLevel = LogLevel.fatal;

    void log(Fields...)(
        LogLevel level,
        string message,
        string file,
        string func,
        size_t line,
        time_t timestamp,
        Fields fields
    )
    {
        if(level < minLogLevel || level > maxLogLevel)
            return;
        this.sink.log(level, message, file, func, line, timestamp, fields);
    }
}
///
unittest
{
    import libbc.log;

    Logger!(
        IsShared.no,
        Sink!(
            "console",
            FilterByLogLevelSink!ConsoleSink
        )
    ) logger;

    logger.console.minLogLevel = LogLevel.info;
    logger.console.maxLogLevel = LogLevel.warning;
    logger.trace("This won't show up");
    logger.error("This won't show up");
    logger.info("But this will");
}