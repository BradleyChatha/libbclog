import core.internal.entrypoint, core.sys.linux.time;
import libbc.log;

mixin _d_cmain;

struct NullSink
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
        static struct NullRange
        {
            @nogc nothrow 
            void put(const char[] str)
            {
            }
        }
        NullRange r;
        jsonToOutputSink(r,
            field!"level"(level),
            field!"message"(message),
            field!"file"(file),
            field!"func"(func),
            field!"line"(line),
            field!"timestamp"(timestamp),
            fields
        );
    }
}

extern(C) int _Dmain(char[][])
{
    enum iterations = 100_000;
    static foreach(test; ["hello_world", "6_fields"])
    {
        bench!(
            "console",
            test,
            iterations,
            Logger!(
                IsShared.no,
                Sink!("_", ConsoleSink)
            )
        )();

        bench!(
            "null",
            test,
            iterations,
            Logger!(
                IsShared.no,
                Sink!("_", NullSink)
            )
        )();

        bench!(
            "file",
            test,
            iterations,
            Logger!(
                IsShared.no,
                Sink!("_", FileSink)
            )
        )();

        import core.stdc.stdio;
        getchar();
    }

    return 0;
}

void bench(string name, string test, size_t iterations, LoggerT)()
{
    LoggerT logger;
    timespec before, after;
    clock_gettime(CLOCK_MONOTONIC, &before);
    clock_gettime(CLOCK_MONOTONIC, &after);
    const timeJustToGetDiff = getDiff(before, after);

    static if(name == "file")
        logger._.open("test.log");

    ulong microsecs;
    ulong nanosecs;

    foreach(i; 0..iterations)
    {
        clock_gettime(CLOCK_MONOTONIC, &before);
        static if(test == "hello_world")
        {
            logger.info("Hello World!");
        }
        else static if(test == "6_fields")
        {
            static const ARRAY_1 = [1,2,3,4,5,6,7,8,9,10];
            static const ARRAY_2 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
            static struct B
            {
                string str;
                int num;
            }
            static struct A
            {
                string str;
                int num;
                B b;
            }
            static const STRUCT = A("abc", 123, B("cba", 321));
            logger.info(
                "This one has 6 fields!",
                field!"1"("string"),
                field!"2"(2020),
                field!"3"(true),
                field!"4"(ARRAY_1),
                field!"5"(ARRAY_2),
                field!"6"(STRUCT),
            );
        }
        clock_gettime(CLOCK_MONOTONIC, &after);
        nanosecs += getDiff(before, after) - timeJustToGetDiff;
        microsecs += (getDiff(before, after) / 1000) - (timeJustToGetDiff / 1000);
    }

    import core.stdc.stdio;
    printf("%s %s @ %lld iterations - %lld nano_seconds/op or %lld micro_seconds/op - %lld nano_seconds total or %lld micro_seconds total\n", 
        name.ptr, 
        test.ptr,
        iterations,
        nanosecs / iterations,
        microsecs / iterations,
        nanosecs,
        microsecs);
}

pragma(inline, true)
ulong getDiff(timespec before, timespec after)
{
    const secs2nsecs = (after.tv_sec - before.tv_sec) * 1000000000;
    const nsecs = (after.tv_nsec - before.tv_nsec);
    return (secs2nsecs + nsecs);
}