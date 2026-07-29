# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0

@testset "Cached clocks" begin
    epoch = CachedEpochClock()
    epoch_micro = CachedEpochMicroClock()
    epoch_nano = CachedEpochNanoClock()
    nano = CachedNanoClock()

    @test epoch isa AbstractEpochClock
    @test epoch_micro isa AbstractEpochMicroClock
    @test epoch_nano isa AbstractEpochNanoClock
    @test nano isa AbstractNanoClock
    @test time_millis(epoch) == 0
    @test time_micros(epoch_micro) == 0
    @test time_nanos(epoch_nano) == 0
    @test time_nanos(nano) == 0
    @test time_millis(CachedEpochClock(123)) == 123
    @test time_micros(CachedEpochMicroClock(234)) == 234
    @test time_nanos(CachedEpochNanoClock(345)) == 345
    @test time_nanos(CachedNanoClock(456)) == 456

    @test !applicable(time_micros, epoch)
    @test !applicable(time_nanos, epoch)
    @test !applicable(time_millis, epoch_micro)
    @test !applicable(time_nanos, epoch_micro)
    @test !applicable(time_millis, epoch_nano)
    @test !applicable(time_micros, epoch_nano)
    @test !applicable(time_millis, nano)
    @test !applicable(time_micros, nano)

    @test @inferred(update!(epoch, Int64(1_000))) == 1_000
    @test @inferred(advance!(epoch, Int64(7))) == 1_007
    @test @inferred(time_millis(epoch)) == 1_007

    @test @inferred(update!(epoch_micro, Int64(2_000))) == 2_000
    @test @inferred(advance!(epoch_micro, Int64(8))) == 2_008
    @test @inferred(time_micros(epoch_micro)) == 2_008

    @test @inferred(update!(epoch_nano, Int64(3_000))) == 3_000
    @test @inferred(advance!(epoch_nano, Int64(9))) == 3_009
    @test @inferred(time_nanos(epoch_nano)) == 3_009

    @test @inferred(update!(nano, Int64(1_000_000))) == 1_000_000
    @test @inferred(advance!(nano, Int64(-1))) == 999_999
    @test @inferred(time_nanos(nano)) == 999_999

    @test update!(epoch, Int32(42)) == 42
    @test advance!(epoch, Int16(2)) == 44
    @test update!(epoch_micro, Int32(52)) == 52
    @test advance!(epoch_micro, Int16(3)) == 55
    @test update!(epoch_nano, Int32(62)) == 62
    @test advance!(epoch_nano, Int16(4)) == 66
    @test update!(nano, Int32(7)) == 7
    @test advance!(nano, Int16(2)) == 9

    @test fieldoffset(CachedEpochClock, 2) == Clocks.CACHE_LINE_PAD
    @test fieldoffset(CachedEpochMicroClock, 2) == Clocks.CACHE_LINE_PAD
    @test fieldoffset(CachedEpochNanoClock, 2) == Clocks.CACHE_LINE_PAD
    @test fieldoffset(CachedNanoClock, 2) == Clocks.CACHE_LINE_PAD
    @test sizeof(CachedEpochClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test sizeof(CachedEpochMicroClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test sizeof(CachedEpochNanoClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test sizeof(CachedNanoClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test Clocks.CACHE_LINE_PAD == 128

    @testset "single-writer publication" begin
        clocks_and_readers = (
            (CachedEpochClock(), time_millis),
            (CachedEpochMicroClock(), time_micros),
            (CachedEpochNanoClock(), time_nanos),
            (CachedNanoClock(), time_nanos),
        )

        for (clock, read_clock) in clocks_and_readers
            iterations = 100_000
            writer = Threads.@spawn begin
                for value in 1:iterations
                    update!(clock, value)
                    iszero(value & 0x3ff) && yield()
                end
            end
            readers = [Threads.@spawn begin
                previous = typemin(Int64)
                ordered = true
                for i in 1:iterations
                    current = read_clock(clock)
                    ordered &= current >= previous
                    previous = current
                    iszero(i & 0x3ff) && yield()
                end
                ordered
            end for _ in 1:max(2, Threads.nthreads() - 1)]

            wait(writer)
            @test all(fetch, readers)
            @test read_clock(clock) == iterations
        end
    end
end
