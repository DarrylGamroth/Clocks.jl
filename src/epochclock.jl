using LibUV_jll

struct UVTimespec
    tv_sec::Int64
    tv_nsec::Int32
end

const UV_REALTIME::Cint = 1

"""
    epoch_time()

Returns the current epoch time as a `TimeSpec` struct.
"""
@inline function epoch_time()
    ts = Ref{UVTimespec}()
    err = @ccall uv_clock_gettime(UV_REALTIME::Cint, ts::Ref{UVTimespec})::Cint
    if err != 0
        error("uv_clock_gettime error: $(unsafe_string(@ccall uv_strerror(err::Cint)::Ptr{Cchar}))")
    end
    return ts[]
end

"""
    EpochClock()

A clock that returns the current epoch time.
"""
struct EpochClock <: AbstractClock end

"""
    time_millis(::EpochClock)

Returns the current time in milliseconds since the epoch.
"""
@inline function time_millis(::EpochClock)
    ts = epoch_time()
    return ts.tv_sec * 1_000 + ts.tv_nsec ÷ 1_000_000
end

"""
    time_micros(::EpochClock)

Returns the current time in microseconds since the epoch.
"""
@inline function time_micros(::EpochClock)
    ts = epoch_time()
    return ts.tv_sec * 1_000_000 + ts.tv_nsec ÷ 1_000
end

"""
    time_nanos(::EpochClock)

Returns the current time in nanoseconds since the epoch.
"""
@inline function time_nanos(::EpochClock)
    ts = epoch_time()
    return ts.tv_sec * 1_000_000_000 + ts.tv_nsec
end
