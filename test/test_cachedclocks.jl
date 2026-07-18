@testset "Cached clocks" begin
    epoch = CachedEpochClock()
    nano = CachedNanoClock()

    @test epoch isa AbstractEpochClock
    @test nano isa AbstractNanoClock
    @test time_millis(epoch) == 0
    @test time_nanos(nano) == 0
    @test time_millis(CachedEpochClock(123)) == 123
    @test time_nanos(CachedNanoClock(456)) == 456

    @test !applicable(time_nanos, epoch)
    @test !applicable(time_millis, nano)

    @test @inferred(update!(epoch, Int64(1_000))) == 1_000
    @test @inferred(advance!(epoch, Int64(7))) == 1_007
    @test @inferred(time_millis(epoch)) == 1_007

    @test @inferred(update!(nano, Int64(1_000_000))) == 1_000_000
    @test @inferred(advance!(nano, Int64(-1))) == 999_999
    @test @inferred(time_nanos(nano)) == 999_999

    @test update!(epoch, Int32(42)) == 42
    @test advance!(nano, Int16(2)) == 1_000_001

    @test fieldoffset(CachedEpochClock, 2) == Clocks.CACHE_LINE_PAD
    @test fieldoffset(CachedNanoClock, 2) == Clocks.CACHE_LINE_PAD
    @test sizeof(CachedEpochClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test sizeof(CachedNanoClock) == 2 * Clocks.CACHE_LINE_PAD + sizeof(Int64)
    @test Clocks.CACHE_LINE_PAD == 128

    @testset "single-writer publication" begin
        clock = CachedNanoClock()
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
                current = time_nanos(clock)
                ordered &= current >= previous
                previous = current
                iszero(i & 0x3ff) && yield()
            end
            ordered
        end for _ in 1:max(2, Threads.nthreads() - 1)]

        wait(writer)
        @test all(fetch, readers)
        @test time_nanos(clock) == iterations
    end
end
