# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0

"""
    epoch_millis()

Return milliseconds since 1 January 1970 UTC. On Julia versions before 1.11,
the result is derived from the floating-point `time()` API.
"""
@inline epoch_millis() = floor(Int64, time() * 1_000)

"""
    epoch_micros()

Return microseconds since 1 January 1970 UTC. On Julia versions before 1.11,
the result is derived from the floating-point `time()` API.
"""
@inline epoch_micros() = floor(Int64, time() * 1_000_000)

"""
    epoch_nanos()

Return nanoseconds since 1 January 1970 UTC. On Julia versions before 1.11,
the result is derived from the floating-point `time()` API and therefore has
less resolution than the return type can represent.
"""
@inline epoch_nanos() = floor(Int64, time() * 1_000_000_000)
