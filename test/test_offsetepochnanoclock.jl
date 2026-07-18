# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0

mutable struct ScriptedEpochNanoClock <: AbstractEpochNanoClock
    values::Vector{Int64}
    index::Int
end

ScriptedEpochNanoClock(values) = ScriptedEpochNanoClock(Int64[values...], 1)

function Clocks.time_nanos(clock::ScriptedEpochNanoClock)
    value = clock.values[clock.index]
    clock.index += 1
    return value
end

mutable struct ScriptedNanoClock <: AbstractNanoClock
    values::Vector{Int64}
    index::Int
end

ScriptedNanoClock(values) = ScriptedNanoClock(Int64[values...], 1)

function Clocks.time_nanos(clock::ScriptedNanoClock)
    value = clock.values[clock.index]
    clock.index += 1
    return value
end

allocated_time_nanos(clock) = @allocated time_nanos(clock)
allocated_within_threshold(clock) = @allocated is_within_threshold(clock)
allocated_sample(clock) = @allocated sample!(clock)

@testset "Offset epoch nano clock" begin
    @testset "sampling within threshold" begin
        epoch = ScriptedEpochNanoClock([1_000])
        nano = ScriptedNanoClock([100, 104, 112])
        clock = OffsetEpochNanoClock(
            epoch,
            nano;
            max_measurement_retries=3,
            measurement_threshold_ns=5,
            resample_interval_ns=1_000,
        )

        @test clock isa AbstractEpochNanoClock
        @test is_within_threshold(clock)
        @test time_nanos(clock) == 1_010
        @test !applicable(time_millis, clock)
        @test !applicable(time_micros, clock)
    end

    @testset "narrowest fallback sample" begin
        epoch = ScriptedEpochNanoClock([1_000, 2_000, 3_000])
        nano = ScriptedNanoClock([100, 120, 200, 208, 300, 306, 310])
        clock = OffsetEpochNanoClock(
            epoch,
            nano;
            max_measurement_retries=3,
            measurement_threshold_ns=5,
            resample_interval_ns=1_000,
        )

        @test !is_within_threshold(clock)
        @test time_nanos(clock) == 3_007
    end

    @testset "automatic and explicit resampling" begin
        epoch = ScriptedEpochNanoClock([1_000, 2_000])
        nano = ScriptedNanoClock([0, 0, 11, 12, 12, 13])
        clock = OffsetEpochNanoClock(
            epoch,
            nano;
            measurement_threshold_ns=1,
            resample_interval_ns=10,
        )

        @test time_nanos(clock) == 2_001

        epoch = ScriptedEpochNanoClock([1_000, 2_000])
        nano = ScriptedNanoClock([100, 100, 99, 90, 90, 91])
        clock = OffsetEpochNanoClock(
            epoch,
            nano;
            measurement_threshold_ns=1,
            resample_interval_ns=10,
        )

        @test time_nanos(clock) == 2_001

        epoch = ScriptedEpochNanoClock([1_000, 2_000])
        nano = ScriptedNanoClock([0, 0, 10, 20, 20, 30])
        clock = OffsetEpochNanoClock(
            epoch,
            nano;
            measurement_threshold_ns=1,
            resample_interval_ns=1,
        )

        # Even a pathologically short interval performs one bounded resample.
        @test time_nanos(clock) == 2_010

        epoch = ScriptedEpochNanoClock([5_000, 6_000])
        nano = ScriptedNanoClock([100, 100, 200, 200])
        clock = OffsetEpochNanoClock(epoch, nano; measurement_threshold_ns=1)
        @test sample!(clock) === clock
        @test is_within_threshold(clock)
    end

    @testset "configuration validation" begin
        @test_throws ArgumentError OffsetEpochNanoClock(max_measurement_retries=0)
        @test_throws ArgumentError OffsetEpochNanoClock(measurement_threshold_ns=-1)
        @test_throws ArgumentError OffsetEpochNanoClock(resample_interval_ns=0)

        epoch = ScriptedEpochNanoClock([1, 2])
        nano = ScriptedNanoClock([2, 1, 4, 3])
        @test_throws ArgumentError OffsetEpochNanoClock(
            epoch,
            nano;
            max_measurement_retries=2,
        )
    end

    @testset "system sources and hot path" begin
        epoch = ScriptedEpochNanoClock(fill(1_000, 100))
        @test OffsetEpochNanoClock(epoch).epoch_clock === epoch

        clock = OffsetEpochNanoClock()
        before = epoch_nanos()
        value = @inferred time_nanos(clock)
        after = epoch_nanos()

        @test before - 1_000_000 <= value <= after + 1_000_000
        @test @inferred(is_within_threshold(clock)) isa Bool

        time_nanos(clock)
        is_within_threshold(clock)
        sample!(clock)
        @test allocated_time_nanos(clock) == 0
        @test allocated_within_threshold(clock) == 0
        @test allocated_sample(clock) == 0
    end

    @testset "concurrent reads and resampling" begin
        clock = OffsetEpochNanoClock()
        readers = [Threads.@spawn begin
            valid = true
            for i in 1:10_000
                value = time_nanos(clock)
                valid &= value > 0
                iszero(i & 0x3ff) && yield()
            end
            valid
        end for _ in 1:max(2, Threads.nthreads() - 1)]

        samplers = [Threads.@spawn begin
            for _ in 1:100
                sample!(clock)
                yield()
            end
        end for _ in 1:2]

        wait.(samplers)
        @test all(fetch, readers)
    end
end
