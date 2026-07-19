# Copyright 2014-2025 Real Logic Limited.
# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Ported from Agrona and substantially modified for Julia.

"""
    SystemEpochClock()

Allocation-free provider of milliseconds since 1 January 1970 UTC.
"""
struct SystemEpochClock <: AbstractEpochClock end

"""
    SystemEpochMicroClock()

Allocation-free provider of microseconds since 1 January 1970 UTC.
"""
struct SystemEpochMicroClock <: AbstractEpochMicroClock end

"""
    SystemEpochNanoClock()

Allocation-free provider of nanoseconds since 1 January 1970 UTC.
"""
struct SystemEpochNanoClock <: AbstractEpochNanoClock end

"""
    SystemNanoClock()

Allocation-free provider of monotonic nanosecond ticks from an arbitrary
origin. Values may wrap and must only be used to measure elapsed time.
"""
struct SystemNanoClock <: AbstractNanoClock end

@inline time_millis(::SystemEpochClock) = epoch_millis()
@inline time_micros(::SystemEpochMicroClock) = epoch_micros()
@inline time_nanos(::SystemEpochNanoClock) = epoch_nanos()
@inline time_nanos(::SystemNanoClock) = reinterpret(Int64, time_ns())
