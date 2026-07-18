struct UVTimespec
    tv_sec::Int64
    tv_nsec::Int32
end

const UV_REALTIME::Cint = 1

@noinline function uv_clock_error(err::Cint)
    message = unsafe_string(@ccall uv_strerror(err::Cint)::Ptr{Cchar})
    error("uv_clock_gettime error: $message")
end

@inline function epoch_time()
    ts = Ref{UVTimespec}()
    err = @ccall uv_clock_gettime(UV_REALTIME::Cint, ts::Ref{UVTimespec})::Cint
    iszero(err) || uv_clock_error(err)
    return ts[]
end

"""
    epoch_millis()

Return milliseconds since 1 January 1970 UTC using Julia's bundled libuv.
"""
@inline function epoch_millis()
    ts = epoch_time()
    return ts.tv_sec * 1_000 + ts.tv_nsec ÷ 1_000_000
end

"""
    epoch_micros()

Return microseconds since 1 January 1970 UTC using Julia's bundled libuv.
"""
@inline function epoch_micros()
    ts = epoch_time()
    return ts.tv_sec * 1_000_000 + ts.tv_nsec ÷ 1_000
end

"""
    epoch_nanos()

Return nanoseconds since 1 January 1970 UTC using Julia's bundled libuv.
"""
@inline function epoch_nanos()
    ts = epoch_time()
    return ts.tv_sec * 1_000_000_000 + ts.tv_nsec
end
