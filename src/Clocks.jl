module Clocks

using Hwloc
using LibUV_jll

export AbstractClock, CachedEpochClock, EpochClock, MonotonicClock, time_millis, time_micros, time_nanos, update!, advance!

const CACHE_LINE_SIZE::Int = maximum(cachelinesize())
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

include("epochclock.jl")
include("monotonicclock.jl")

include("cachedepochclock.jl")

end # module Clocks
