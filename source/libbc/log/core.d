module libbc.log.core;

import libbc.fmt, core.stdc.time, std.traits;
import std.typecons : Flag;

struct Sink(string name_, alias SinkT_)
{
    static const Name = name_;
    alias SinkT = SinkT_;
}

struct Field(string name_, alias ValueT_)
{
    static const Name = name_;
    alias ValueT = ValueT_;

    ValueT value;

    static if(hasElaborateCopyConstructor!ValueT)
    this(ref return scope typeof(this) src)
    {
        this.value = src.value;
    }
}

Field!(name, T) field(string name, T)(T t)
{
    return Field!(name, T)(t);
}

enum LogLevel
{
    trace,
    debug_,
    info,
    warning,
    error,
    fatal
}

alias IsShared = Flag!"isShared";

struct Logger(
    IsShared isShared,
    Sinks...
)
{
    @disable this(this){}

    static foreach(sink; Sinks)
    {
        mixin("sink.SinkT "~sink.Name~";");
    }

    version(Windows)
    {

    }
    else version(posix)
    {
        import core.stdc.pthread, core.stdc.unistd;
        private shared pthread_mutex_t _mutex;
    }

    ~this()
    {
        version(Windows)
        {

        }
        else version(posix)
        {
            if(this._mutex)
                pthread_mutex_destroy(this._mutex);
        }
    }

    void log(string _file = __FILE__, string _func = __FUNCTION__, size_t _line = __LINE__, Fields...)(LogLevel _level, string _message, Fields _fields)
    {
        import core.stdc.time;

        static if(isShared)
        {
            version(Windows)
            {

            }
            else version(posix)
            {
                if(this._mutex == pthread_mutex_t.init)
                {
                    const result = pthread_mutext_init(&this._mutex, null);
                    perror("Could not create mutex.");
                    assert(result, "Could not initialise mutex?");
                }
                pthread_mutex_lock(&this._mutex);
                scope(exit) pthread_mutex_unlock(&this._mutex);
            }
        }

        const _timestamp = time(null);

        static foreach(sink; Sinks)
            mixin(sink.Name~".log(_level, _message, _file, _func, _line, _timestamp, _fields);");
    }

    static foreach(member; __traits(allMembers, LogLevel))
    mixin(
        "void "~member~"(string file = __FILE__, string func = __FUNCTION__, size_t line = __LINE__, Fields...)(string message, Fields fields)"
        ~"{ log!(file, func, line, Fields)(LogLevel."~member~", message, fields); }"
    );
}
///
unittest
{
    import libbc.log.sinks;

    struct S
    {
        string joke;
    }

    Logger!(IsShared.no, Sink!("console", ConsoleSink), Sink!("file", FileSink)) l;
    assert(l.file.open("test.log"));
    l.info("Hello!");
    l.fatal("weeeee", field!"answer to life"(69));
    l.debug_("badum-tiss", field!"S"(S("This is *struct*ured logging.")));

    Logger!(IsShared.yes, Sink!("file", FileSink)) l2;
    l.file.open("shared.log");
    l.info("Sorry", field!"admission"("I don't have a threading library made yet, so can't really test this properly"));
}

void jsonToOutputSink(Sink, Fields...)(auto ref Sink s, Fields fields)
{
    import libbc.ds.string;
    s.put("{");

    void putEscaped(const char[] str)
    {
        size_t start;

        foreach(i, ch; str)
        {
            if(ch == '"' || ch == '\\')
            {
                s.put(str[start..i]);
                if(ch == '"')
                    s.put(`"`);
                else
                    s.put("\\");
                start = i + 1;
            }
        }
        if(start < str.length)
            s.put(str[start..$]);
    }

    void put(T)(ref T value)
    {
        alias ValueT = typeof(value);
        static if(is(ValueT == enum))
        {
            s.put(`"`);
            s.put(enumToString(value));
            s.put(`"`);
        }
        else static if(is(ValueT == bool))
            s.put(value ? "true" : "false");
        else static if(is(ValueT : const(char)[]))
        {
            s.put(`"`);
            putEscaped(value);
            s.put(`"`);
        }
        else static if(is(ValueT == String))
        {
            s.put(`"`);
            putEscaped(value.sliceUnsafe);
            s.put(`"`);
        }
        else static if(is(ValueT == struct))
        {
            s.put("{");
            bool isFirst = true;
            static foreach(name; __traits(allMembers, ValueT))
            {
                static if(__traits(compiles, {put(mixin("value."~name));}))
                {
                    if(!isFirst)
                        s.put(", ");
                    else
                        isFirst = false;

                    s.put(`"`);
                    s.put(name);
                    s.put(`": `);
                    put(mixin("value."~name));
                }
                else
                    version(LIBBC_LOG_DEBUG_SERIALISER) pragma(msg, "[libbclog] Ignoring member "~name~" from "~ValueT.stringof~" because we can't serialise it to JSON.");
            }
            s.put("}");
        }
        else static if(__traits(compiles, {foreach(v; ValueT.init){}}))
        {
            s.put("[");
            bool isFirst = true;
            foreach(v; value)
            {
                if(!isFirst)
                    s.put(", ");
                else
                    isFirst = false;

                put(v);
            }
            s.put("]");
        }
        else static if(isNumeric!ValueT)
        {
            IntToCharBuffer buffer;
            s.put(toBase10(value, buffer));
        }
        else static assert(false, "Don't know how to convert "~ValueT.stringof~" into JSON");
    }

    static foreach(i, f; fields)
    {
        s.put(`"`);
        s.put(f.Name);
        s.put(`": `);

        put(f.value);

        static if(i != Fields.length-1)
            s.put(", ");
    }

    s.put("}");
}