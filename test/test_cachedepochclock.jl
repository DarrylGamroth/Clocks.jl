@testset "CachedEpochClock Tests" begin
    @testset "Constructor" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        @test cached_clock isa CachedEpochClock
        @test cached_clock isa AbstractClock
        @test cached_clock.clock === epoch_clock
        
        # Test with MonotonicClock too
        mono_clock = MonotonicClock()
        cached_mono = CachedEpochClock(mono_clock)
        @test cached_mono isa CachedEpochClock
        @test cached_mono.clock === mono_clock
    end
    
    @testset "Initial State" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Initially, the cached time should be 0 (as set in constructor)
        @test time_nanos(cached_clock) == 0
        @test time_micros(cached_clock) == 0
        @test time_millis(cached_clock) == 0
    end
    
    @testset "fetch! Functionality" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Fetch time from the underlying clock
        fetched_time = fetch!(cached_clock)
        
        @test fetched_time > 0
        @test fetched_time isa Int64
        
        # Cached time should now match the fetched time
        @test time_nanos(cached_clock) == fetched_time
        
        # Test with different time resolutions
        @test time_micros(cached_clock) == fetched_time ÷ 1_000
        @test time_millis(cached_clock) == fetched_time ÷ 1_000_000
    end
    
    @testset "update! Functionality" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Update with a specific time
        test_time = 1_234_567_890_123_456_789
        update!(cached_clock, test_time)
        
        @test time_nanos(cached_clock) == test_time
        @test time_micros(cached_clock) == test_time ÷ 1_000
        @test time_millis(cached_clock) == test_time ÷ 1_000_000
    end
    
    @testset "advance! Functionality" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Set initial time
        initial_time = 1_000_000_000_000_000_000
        update!(cached_clock, initial_time)
        
        # Advance by some amount
        advance_amount = 500_000_000  # 500ms in nanos
        advance!(cached_clock, advance_amount)
        
        expected_time = initial_time + advance_amount
        @test time_nanos(cached_clock) == expected_time
        @test time_micros(cached_clock) == expected_time ÷ 1_000
        @test time_millis(cached_clock) == expected_time ÷ 1_000_000
        
        # Test multiple advances
        advance!(cached_clock, 1_000_000)  # 1ms
        advance!(cached_clock, 2_000_000)  # 2ms
        expected_time += 3_000_000  # Total 3ms more
        
        @test time_nanos(cached_clock) == expected_time
    end
    
    @testset "Negative and Zero Advances" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        initial_time = 1_000_000_000_000_000_000
        update!(cached_clock, initial_time)
        
        # Zero advance should not change time
        advance!(cached_clock, 0)
        @test time_nanos(cached_clock) == initial_time
        
        # Negative advance should decrease time
        advance!(cached_clock, -1_000_000)  # -1ms
        @test time_nanos(cached_clock) == initial_time - 1_000_000
    end
    
    @testset "Time Consistency" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Fetch current time
        fetch!(cached_clock)
        
        # Multiple reads should return the same value (since it's cached)
        t1 = time_nanos(cached_clock)
        t2 = time_nanos(cached_clock)
        t3 = time_nanos(cached_clock)
        
        @test t1 == t2 == t3
        
        # Same for other resolutions
        m1 = time_millis(cached_clock)
        m2 = time_millis(cached_clock)
        @test m1 == m2
        
        u1 = time_micros(cached_clock)
        u2 = time_micros(cached_clock)
        @test u1 == u2
    end
    
    @testset "Integration with Different Clocks" begin
        # Test with EpochClock
        epoch_clock = EpochClock()
        cached_epoch = CachedEpochClock(epoch_clock)
        epoch_time = fetch!(cached_epoch)
        @test epoch_time > 1_577_836_800_000_000_000  # Should be epoch time
        
        # Test with MonotonicClock
        mono_clock = MonotonicClock()
        cached_mono = CachedEpochClock(mono_clock)
        mono_time = fetch!(cached_mono)
        @test mono_time > 0  # Should be positive monotonic time
        
        # Times should be different (different types of clocks)
        @test abs(epoch_time - mono_time) > 1_000_000  # Should differ significantly
    end
    
    @testset "Large Values" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Test with large time values
        large_time = typemax(Int64) ÷ 2  # Large but safe value
        update!(cached_clock, large_time)
        
        @test time_nanos(cached_clock) == large_time
        @test time_micros(cached_clock) == large_time ÷ 1_000
        @test time_millis(cached_clock) == large_time ÷ 1_000_000
        
        # Test advancing from large value
        advance!(cached_clock, 1_000_000)
        @test time_nanos(cached_clock) == large_time + 1_000_000
    end
    
    @testset "Memory Layout and Padding" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Test that the struct has the expected fields
        @test hasfield(typeof(cached_clock), :clock)
        @test hasfield(typeof(cached_clock), :pad1)
        @test hasfield(typeof(cached_clock), :time_ns)
        @test hasfield(typeof(cached_clock), :pad2)
        
        # Test that padding is the expected size
        @test sizeof(cached_clock.pad1) == Clocks.CACHE_LINE_PAD
        @test sizeof(cached_clock.pad2) == Clocks.CACHE_LINE_PAD
    end
    
    @testset "Type Stability" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Test that all functions return stable types
        @test @inferred(time_nanos(cached_clock)) isa Int64
        @test @inferred(time_micros(cached_clock)) isa Int64
        @test @inferred(time_millis(cached_clock)) isa Int64
        
        @test @inferred(fetch!(cached_clock)) isa Int64
        
        # update! and advance! return the time value
        @test @inferred(update!(cached_clock, 123)) isa Int64
        @test @inferred(advance!(cached_clock, 456)) isa Int64
    end
    
    @testset "Edge Cases" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Test with zero time
        update!(cached_clock, 0)
        @test time_nanos(cached_clock) == 0
        @test time_micros(cached_clock) == 0
        @test time_millis(cached_clock) == 0
        
        # Test with very small advances
        update!(cached_clock, 1_000_000_000)  # 1 second in nanos
        advance!(cached_clock, 1)  # 1 nanosecond
        @test time_nanos(cached_clock) == 1_000_000_001
        
        # Microsecond resolution should round down
        @test time_micros(cached_clock) == 1_000_000  # Should be 1_000_000.001 → 1_000_000
    end
end