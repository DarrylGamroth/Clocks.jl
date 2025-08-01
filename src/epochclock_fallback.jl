"""
    EpochClock()

A clock that returns the current epoch time.
Fallback implementation using time() for Julia versions prior to 1.11.
"""
struct EpochClock <: AbstractClock end

"""
    time_millis(::EpochClock)

Returns the current time in milliseconds since the epoch.
"""
@inline function time_millis(::EpochClock)
    return round(Int64, time() * 1_000)
end

"""
    time_micros(::EpochClock)

Returns the current time in microseconds since the epoch.
"""
@inline function time_micros(::EpochClock)
    return round(Int64, time() * 1_000_000)
end

"""
    time_nanos(::EpochClock)

Returns the current time in nanoseconds since the epoch.
Note: Limited by time() precision, typically microsecond resolution.
"""
@inline function time_nanos(::EpochClock)
    return round(Int64, time() * 1_000_000_000)
end
