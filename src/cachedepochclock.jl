"""
    CachedEpochClock(clock::AbstractClock)

A clock that caches a value from another clock to reduce the frequency of calls to the underlying clock.
"""
mutable struct CachedEpochClock{C<:AbstractClock} <: AbstractClock
    clock::C
    const pad1::NTuple{CACHE_LINE_PAD,Int8}
    @atomic time_ns::Int64
    const pad2::NTuple{CACHE_LINE_PAD,Int8}
    CachedEpochClock(c::T) where {T} = new{T}(c, ntuple(i -> 0, CACHE_LINE_PAD), 0, ntuple(i -> 0, CACHE_LINE_PAD))
end

"""
    time_millis(c::CachedEpochClock)

Returns the current time in milliseconds from the cached value.
"""
time_millis(c::CachedEpochClock) = (@atomic :acquire c.time_ns) ÷ 1_000_000

"""
    time_micros(c::CachedEpochClock)

Returns the current time in microseconds from the cached value.
"""
time_micros(c::CachedEpochClock) = (@atomic :acquire c.time_ns) ÷ 1_000

"""
    time_nanos(c::CachedEpochClock)

Returns the current time in nanoseconds from the cached value.
"""
time_nanos(c::CachedEpochClock) = @atomic :acquire c.time_ns

"""
    update!(c::CachedEpochClock, time_ns)

Updates the cached time with the given nanoseconds.
"""
update!(c::CachedEpochClock, time_ns) = @atomic :release c.time_ns = time_ns

"""
    advance!(c::CachedEpochClock, nanos)

Advances the cached time by the given nanoseconds.
"""
advance!(c::CachedEpochClock, nanos) = @atomic :acquire_release c.time_ns += nanos

"""
    fetch!(c::CachedEpochClock)

Fetches the current time from the clock and updates the cached value.
"""
function fetch!(c::CachedEpochClock)
    time_ns = time_nanos(c.clock)
    update!(c, time_ns)
    return time_ns
end
