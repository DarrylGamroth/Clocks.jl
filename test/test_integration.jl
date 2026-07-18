# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0

struct FixedEpochClock <: AbstractEpochClock
    time_ms::Int64
end

Clocks.time_millis(clock::FixedEpochClock) = clock.time_ms

struct FixedNanoClock <: AbstractNanoClock
    time_ns::Int64
end

Clocks.time_nanos(clock::FixedNanoClock) = clock.time_ns

@testset "Provider integration" begin
    epoch_source = FixedEpochClock(123)
    nano_source = FixedNanoClock(456)
    cached_epoch = CachedEpochClock()
    cached_nano = CachedNanoClock()

    update!(cached_epoch, time_millis(epoch_source))
    update!(cached_nano, time_nanos(nano_source))
    @test time_millis(cached_epoch) == 123
    @test time_nanos(cached_nano) == 456

    @test !isdefined(Clocks, :EpochClock)
    @test !isdefined(Clocks, :MonotonicClock)
    @test !isdefined(Clocks, :CachedMonotonicClock)
    @test !isdefined(Clocks, :fetch!)

    for name in names(Clocks)
        @test isdefined(Clocks, name)
    end
end
