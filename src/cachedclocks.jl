# Copyright 2014-2025 Real Logic Limited.
# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Ported from Agrona and substantially modified for Julia.

"""
    CachedEpochClock([initial_time_ms=0])

Manually updated provider of milliseconds since 1 January 1970 UTC. One
thread or agent must own calls to [`update!`](@ref) and [`advance!`](@ref);
any number of threads may call [`time_millis`](@ref).
"""
mutable struct CachedEpochClock <: AbstractEpochClock
    const pad1::NTuple{CACHE_LINE_PAD_WORDS,UInt64}
    @atomic time_ms::Int64
    const pad2::NTuple{CACHE_LINE_PAD_WORDS,UInt64}

    function CachedEpochClock(initial_time_ms::Integer=0)
        return new(CACHE_LINE_PADDING, Int64(initial_time_ms), CACHE_LINE_PADDING)
    end
end

"""
    CachedEpochMicroClock([initial_time_us=0])

Manually updated provider of microseconds since 1 January 1970 UTC. One
thread or agent must own calls to [`update!`](@ref) and [`advance!`](@ref);
any number of threads may call [`time_micros`](@ref).
"""
mutable struct CachedEpochMicroClock <: AbstractEpochMicroClock
    const pad1::NTuple{CACHE_LINE_PAD_WORDS,UInt64}
    @atomic time_us::Int64
    const pad2::NTuple{CACHE_LINE_PAD_WORDS,UInt64}

    function CachedEpochMicroClock(initial_time_us::Integer=0)
        return new(CACHE_LINE_PADDING, Int64(initial_time_us), CACHE_LINE_PADDING)
    end
end

"""
    CachedEpochNanoClock([initial_time_ns=0])

Manually updated provider of nanoseconds since 1 January 1970 UTC. One
thread or agent must own calls to [`update!`](@ref) and [`advance!`](@ref);
any number of threads may call [`time_nanos`](@ref).
"""
mutable struct CachedEpochNanoClock <: AbstractEpochNanoClock
    const pad1::NTuple{CACHE_LINE_PAD_WORDS,UInt64}
    @atomic time_ns::Int64
    const pad2::NTuple{CACHE_LINE_PAD_WORDS,UInt64}

    function CachedEpochNanoClock(initial_time_ns::Integer=0)
        return new(CACHE_LINE_PADDING, Int64(initial_time_ns), CACHE_LINE_PADDING)
    end
end

"""
    CachedNanoClock([initial_time_ns=0])

Manually updated provider of monotonic nanosecond ticks. One thread or agent
must own calls to [`update!`](@ref) and [`advance!`](@ref); any number of
threads may call [`time_nanos`](@ref).
"""
mutable struct CachedNanoClock <: AbstractNanoClock
    const pad1::NTuple{CACHE_LINE_PAD_WORDS,UInt64}
    @atomic time_ns::Int64
    const pad2::NTuple{CACHE_LINE_PAD_WORDS,UInt64}

    function CachedNanoClock(initial_time_ns::Integer=0)
        return new(CACHE_LINE_PADDING, Int64(initial_time_ns), CACHE_LINE_PADDING)
    end
end

@inline time_millis(c::CachedEpochClock) = @atomic :acquire c.time_ms
@inline time_micros(c::CachedEpochMicroClock) = @atomic :acquire c.time_us
@inline time_nanos(c::CachedEpochNanoClock) = @atomic :acquire c.time_ns
@inline time_nanos(c::CachedNanoClock) = @atomic :acquire c.time_ns

"""
    update!(clock::CachedEpochClock, time_ms)
    update!(clock::CachedEpochMicroClock, time_us)
    update!(clock::CachedEpochNanoClock, time_ns)
    update!(clock::CachedNanoClock, time_ns)

Publish an absolute cached time with release ordering. A cached clock has one
updating owner and any number of readers.
"""
@inline update!(c::CachedEpochClock, time_ms::Int64) =
    @atomic :release c.time_ms = time_ms
@inline update!(c::CachedEpochMicroClock, time_us::Int64) =
    @atomic :release c.time_us = time_us
@inline update!(c::CachedEpochNanoClock, time_ns::Int64) =
    @atomic :release c.time_ns = time_ns
@inline update!(c::CachedNanoClock, time_ns::Int64) =
    @atomic :release c.time_ns = time_ns

@inline update!(c::CachedEpochClock, time_ms::Integer) =
    update!(c, Int64(time_ms))
@inline update!(c::CachedEpochMicroClock, time_us::Integer) =
    update!(c, Int64(time_us))
@inline update!(c::CachedEpochNanoClock, time_ns::Integer) =
    update!(c, Int64(time_ns))
@inline update!(c::CachedNanoClock, time_ns::Integer) =
    update!(c, Int64(time_ns))

"""
    advance!(clock::CachedEpochClock, millis)
    advance!(clock::CachedEpochMicroClock, micros)
    advance!(clock::CachedEpochNanoClock, nanos)
    advance!(clock::CachedNanoClock, nanos)

Advance a cached time and publish the result with release ordering. This is a
single-writer operation, not an atomic multi-writer increment.
"""
@inline function advance!(c::CachedEpochClock, millis::Int64)
    time_ms = (@atomic :monotonic c.time_ms) + millis
    @atomic :release c.time_ms = time_ms
end

@inline function advance!(c::CachedEpochMicroClock, micros::Int64)
    time_us = (@atomic :monotonic c.time_us) + micros
    @atomic :release c.time_us = time_us
end

@inline function advance!(c::CachedEpochNanoClock, nanos::Int64)
    time_ns = (@atomic :monotonic c.time_ns) + nanos
    @atomic :release c.time_ns = time_ns
end

@inline function advance!(c::CachedNanoClock, nanos::Int64)
    time_ns = (@atomic :monotonic c.time_ns) + nanos
    @atomic :release c.time_ns = time_ns
end

@inline advance!(c::CachedEpochClock, millis::Integer) =
    advance!(c, Int64(millis))
@inline advance!(c::CachedEpochMicroClock, micros::Integer) =
    advance!(c, Int64(micros))
@inline advance!(c::CachedEpochNanoClock, nanos::Integer) =
    advance!(c, Int64(nanos))
@inline advance!(c::CachedNanoClock, nanos::Integer) =
    advance!(c, Int64(nanos))
