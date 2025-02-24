"""
    MonotonicClock()

A clock that returns the current time from an arbitrary epoch.
"""
struct MonotonicClock <: AbstractClock end

"""
    time_millis(::MonotonicCLock)

Returns the current time in milliseconds.
"""
time_millis(::MonotonicClock) = time_ns() ÷ 1_000_000

"""
    time_micros(::MonotonicCLock)

Returns the current time in microseconds.
"""
time_micros(::MonotonicClock) = time_ns() ÷ 1_000


"""
    time_nanos(::MonotonicClock)

Returns the current time in nanoseconds.
"""
time_nanos(::MonotonicClock) = time_ns()
