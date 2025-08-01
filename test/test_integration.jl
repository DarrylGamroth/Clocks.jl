@testset "Integration Tests" begin
    @testset "Clock Comparison" begin
        epoch_clock = EpochClock()
        mono_clock = MonotonicClock()
        
        # Get times from both clocks
        epoch_nanos = time_nanos(epoch_clock)
        mono_nanos = time_nanos(mono_clock)
        
        # Both should be positive
        @test epoch_nanos > 0
        @test mono_nanos > 0
        
        # EpochClock should give larger values (since it's wall clock time)
        # MonotonicClock is relative to system start
        @test epoch_nanos > mono_nanos
        
        # Both should be reasonable values
        @test epoch_nanos > 1_577_836_800_000_000_000  # After 2020
        @test mono_nanos > 0
    end
    
    @testset "CachedEpochClock with Different Underlying Clocks" begin
        epoch_clock = EpochClock()
        mono_clock = MonotonicClock()
        
        cached_epoch = CachedEpochClock(epoch_clock)
        cached_mono = CachedEpochClock(mono_clock)
        
        # Fetch times
        epoch_time = fetch!(cached_epoch)
        mono_time = fetch!(cached_mono)
        
        # Verify they cached the correct values
        @test time_nanos(cached_epoch) == epoch_time
        @test time_nanos(cached_mono) == mono_time
        
        # Values should be different
        @test epoch_time != mono_time
        @test epoch_time > mono_time  # Epoch time should be larger
    end
    
    @testset "Multiple CachedEpochClocks" begin
        epoch_clock = EpochClock()
        
        # Create multiple cached clocks with the same underlying clock
        cached1 = CachedEpochClock(epoch_clock)
        cached2 = CachedEpochClock(epoch_clock)
        cached3 = CachedEpochClock(epoch_clock)
        
        # Fetch times (should be close but may differ slightly)
        time1 = fetch!(cached1)
        time2 = fetch!(cached2)
        time3 = fetch!(cached3)
        
        # All should be reasonable epoch times
        for t in [time1, time2, time3]
            @test t > 1_577_836_800_000_000_000  # After 2020
            @test t < 2_208_988_800_000_000_000  # Before 2040
        end
        
        # They should be close (within reasonable time difference)
        max_diff = max(abs(time1 - time2), abs(time2 - time3), abs(time1 - time3))
        @test max_diff < 10_000_000  # Within 10ms
    end
    
    @testset "Cache Independence" begin
        epoch_clock = EpochClock()
        
        cached1 = CachedEpochClock(epoch_clock)
        cached2 = CachedEpochClock(epoch_clock)
        
        # Set different times in each cache
        time1 = 1_000_000_000_000_000_000
        time2 = 2_000_000_000_000_000_000
        
        update!(cached1, time1)
        update!(cached2, time2)
        
        # Verify independence
        @test time_nanos(cached1) == time1
        @test time_nanos(cached2) == time2
        @test time_nanos(cached1) != time_nanos(cached2)
        
        # Advance one and verify the other is unchanged
        advance!(cached1, 1_000_000)
        @test time_nanos(cached1) == time1 + 1_000_000
        @test time_nanos(cached2) == time2  # Should be unchanged
    end
    
    @testset "Performance Characteristics" begin
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Fetch initial time
        fetch!(cached_clock)
        
        # Measure time for direct clock access
        epoch_times = []
        epoch_duration = @elapsed begin
            for i in 1:1000
                push!(epoch_times, time_nanos(epoch_clock))
            end
        end
        
        # Measure time for cached clock access
        cached_times = []
        cached_duration = @elapsed begin
            for i in 1:1000
                push!(cached_times, time_nanos(cached_clock))
            end
        end
        
        # Cached access should be faster (or at least not significantly slower)
        # This is more of a smoke test than a hard requirement
        @test cached_duration <= epoch_duration * 2  # Allow some overhead
        
        # Cached times should all be identical
        @test all(t -> t == cached_times[1], cached_times)
        
        # Epoch times should have some variation
        @test length(unique(epoch_times)) > 1
    end
    
    @testset "Time Unit Conversions" begin
        # Test consistency across all clock types
        clocks = [EpochClock(), MonotonicClock()]
        
        for clock in clocks
            nanos = time_nanos(clock)
            micros = time_micros(clock)
            millis = time_millis(clock)
            
            # Test conversion relationships (allowing for timing differences)
            @test abs(micros - nanos ÷ 1_000) <= 10  # Allow for timing variation
            @test abs(millis - nanos ÷ 1_000_000) <= 10  # Allow for timing variation
            @test abs(millis - micros ÷ 1_000) <= 10  # Allow for timing variation
        end
        
        # Test with cached clocks
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Set a specific time for exact testing
        test_time = 1_234_567_890_123_456  # Known value for exact division
        update!(cached_clock, test_time)
        
        @test time_nanos(cached_clock) == test_time
        @test time_micros(cached_clock) == test_time ÷ 1_000
        @test time_millis(cached_clock) == test_time ÷ 1_000_000
    end
    
    @testset "Concurrent Access Simulation" begin
        # Test that multiple operations on cached clock work correctly
        epoch_clock = EpochClock()
        cached_clock = CachedEpochClock(epoch_clock)
        
        # Initialize
        initial_time = fetch!(cached_clock)
        
        # Simulate concurrent operations (sequential, but testing atomicity)
        operations = [
            () -> advance!(cached_clock, 1_000_000),  # +1ms
            () -> advance!(cached_clock, -500_000),   # -0.5ms
            () -> time_nanos(cached_clock),           # read
            () -> update!(cached_clock, initial_time + 2_000_000),  # set to +2ms
            () -> time_millis(cached_clock),          # read
            () -> advance!(cached_clock, 3_000_000),  # +3ms
        ]
        
        results = []
        for op in operations
            push!(results, op())
        end
        
        # Final time should be initial_time + 2ms + 3ms = initial_time + 5ms
        final_time = time_nanos(cached_clock)
        expected_final = initial_time + 5_000_000
        @test final_time == expected_final
    end
    
    @testset "Error Conditions and Edge Cases" begin
        # Test with various clock configurations
        epoch_clock = EpochClock()
        mono_clock = MonotonicClock()
        
        # Test creating cached clocks with different underlying clocks
        cached_epoch = CachedEpochClock(epoch_clock)
        cached_mono = CachedEpochClock(mono_clock)
        
        # Test extreme values
        max_safe_value = typemax(Int64) ÷ 2
        update!(cached_epoch, max_safe_value)
        @test time_nanos(cached_epoch) == max_safe_value
        
        # Test that we can still do arithmetic without overflow
        advance!(cached_epoch, -1_000_000)
        @test time_nanos(cached_epoch) == max_safe_value - 1_000_000
        
        # Test minimum values
        min_value = typemin(Int64) ÷ 2
        update!(cached_mono, min_value)
        @test time_nanos(cached_mono) == min_value
    end
    
    @testset "Module Interface" begin
        # Test that all exported functions work
        @test AbstractClock isa Type
        @test EpochClock isa Type
        @test MonotonicClock isa Type
        @test CachedEpochClock isa Type
        
        # Test that time functions are available
        epoch_clock = EpochClock()
        @test time_millis(epoch_clock) isa Int64
        @test time_micros(epoch_clock) isa Int64
        @test time_nanos(epoch_clock) isa Int64
        
        # Test that cache functions are available
        cached_clock = CachedEpochClock(epoch_clock)
        @test fetch!(cached_clock) isa Int64
        @test update!(cached_clock, 123) isa Int64
        @test advance!(cached_clock, 456) isa Int64
    end
end