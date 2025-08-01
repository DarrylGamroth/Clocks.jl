module Clocks

using Hwloc

export AbstractClock, CachedEpochClock, EpochClock, MonotonicClock, time_millis, time_micros, time_nanos, update!, advance!, fetch!

const CACHE_LINE_SIZE::Int = cachelinesize(:L1)
const CACHE_LINE_PAD::Int = CACHE_LINE_SIZE - sizeof(Int64)

"""
    AbstractClock

Abstract type for all clocks.
"""
abstract type AbstractClock end

"""
    time_millis(clock)

Returns the current time in milliseconds.
"""
function time_millis end
"""
    time_micros(clock)

Returns the current time in microseconds.
"""
function time_micros end
"""
    time_nanos(clock)

Returns the current time in nanoseconds.
"""
function time_nanos end

# Use high-precision LibUV implementation on Julia 1.11+, fallback on older versions
if VERSION >= v"1.11"
    using LibUV_jll
    include("epochclock.jl")
else
    include("epochclock_fallback.jl")
end
include("monotonicclock.jl")

include("cachedepochclock.jl")

end # module Clocks
