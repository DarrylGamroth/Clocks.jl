# Copyright 2014-2025 Real Logic Limited.
# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Ported from Agrona and substantially modified for Julia.

"""
Allocation-free epoch and monotonic clock providers modeled on Agrona's clock
contracts.
"""
module Clocks

export AbstractClock, AbstractEpochClock, AbstractEpochMicroClock,
    AbstractEpochNanoClock, AbstractNanoClock,
    SystemEpochClock, SystemEpochMicroClock, SystemEpochNanoClock,
    SystemNanoClock, OffsetEpochNanoClock, CachedEpochClock, CachedNanoClock,
    epoch_millis, epoch_micros, epoch_nanos,
    time_millis, time_micros, time_nanos,
    update!, advance!, sample!, is_within_threshold

# Use a conservative destructive-interference distance that covers common
# 64-byte and 128-byte cache lines without topology discovery at package load.
# A full pad on each side isolates the atomic value regardless of alignment.
const CACHE_LINE_PAD::Int = 128
const CACHE_LINE_PAD_WORDS::Int = CACHE_LINE_PAD ÷ sizeof(UInt64)
const CACHE_LINE_PADDING = ntuple(_ -> UInt64(0), CACHE_LINE_PAD_WORDS)

"""
    AbstractClock

Root type for clock providers. Concrete providers implement exactly one clock
contract so that elapsed-time ticks cannot be confused with epoch timestamps.
"""
abstract type AbstractClock end

"""
    AbstractEpochClock <: AbstractClock

Provider of milliseconds since 1 January 1970 UTC. Implement
[`time_millis`](@ref) for concrete subtypes.
"""
abstract type AbstractEpochClock <: AbstractClock end

"""
    AbstractEpochMicroClock <: AbstractClock

Provider of microseconds since 1 January 1970 UTC. Implement
[`time_micros`](@ref) for concrete subtypes.
"""
abstract type AbstractEpochMicroClock <: AbstractClock end

"""
    AbstractEpochNanoClock <: AbstractClock

Provider of nanoseconds since 1 January 1970 UTC. Implement
[`time_nanos`](@ref) for concrete subtypes.
"""
abstract type AbstractEpochNanoClock <: AbstractClock end

"""
    AbstractNanoClock <: AbstractClock

Provider of monotonic nanosecond ticks from an arbitrary origin. Values are
only suitable for measuring elapsed time. Implement [`time_nanos`](@ref) for
concrete subtypes.
"""
abstract type AbstractNanoClock <: AbstractClock end

"""
    time_millis(clock::AbstractEpochClock)

Return milliseconds since 1 January 1970 UTC.
"""
function time_millis end

"""
    time_micros(clock::AbstractEpochMicroClock)

Return microseconds since 1 January 1970 UTC.
"""
function time_micros end

"""
    time_nanos(clock::Union{AbstractEpochNanoClock,AbstractNanoClock})

Return either epoch nanoseconds or monotonic nanosecond ticks according to the
clock's concrete contract.
"""
function time_nanos end

if VERSION >= v"1.11"
    include("highresolutionclock.jl")
else
    include("highresolutionclock_fallback.jl")
end

include("systemclocks.jl")
include("offsetepochnanoclock.jl")
include("cachedclocks.jl")

end # module Clocks
