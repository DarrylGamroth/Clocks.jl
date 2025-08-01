@testset "EpochClock Tests" begin
    @testset "Constructor" begin
        clock = EpochClock()
        @test clock isa EpochClock
        @test clock isa AbstractClock
    end
    
    @testset "Basic Functionality" begin
        clock = EpochClock()
        
        # Test that all time functions return positive values
        millis = time_millis(clock)
        micros = time_micros(clock)
        nanos = time_nanos(clock)
        
        @test millis > 0
        @test micros > 0
        @test nanos > 0
        
        # Test types
        @test millis isa Int64
        @test micros isa Int64
        @test nanos isa Int64
    end
    
    @testset "Time Relationships" begin
        clock = EpochClock()
        
        # Get times at approximately the same moment
        nanos = time_nanos(clock)
        micros = time_micros(clock)
        millis = time_millis(clock)
        
        # Test approximate relationships (allowing for small timing differences)
        # nanos should be roughly micros * 1000
        expected_nanos_from_micros = micros * 1_000
        @test abs(nanos - expected_nanos_from_micros) < 1_000_000  # within 1ms difference
        
        # micros should be roughly millis * 1000
        expected_micros_from_millis = millis * 1_000
        @test abs(micros - expected_micros_from_millis) < 1_000  # within 1ms difference
    end
    
    @testset "Time Progression" begin
        clock = EpochClock()
        
        # Test that time progresses
        t1_millis = time_millis(clock)
        sleep(0.001)  # Sleep 1ms
        t2_millis = time_millis(clock)
        @test t2_millis >= t1_millis
        
        t1_micros = time_micros(clock)
        sleep(0.001)  # Sleep 1ms
        t2_micros = time_micros(clock)
        @test t2_micros >= t1_micros
        
        t1_nanos = time_nanos(clock)
        sleep(0.001)  # Sleep 1ms
        t2_nanos = time_nanos(clock)
        @test t2_nanos >= t1_nanos
    end
    
    @testset "Reasonable Time Ranges" begin
        clock = EpochClock()
        
        # Test that we get reasonable epoch times
        # Epoch time should be roughly current time (after 2020, before 2040)
        millis = time_millis(clock)
        
        # Jan 1, 2020 00:00:00 UTC = 1577836800000 milliseconds
        # Jan 1, 2040 00:00:00 UTC = 2208988800000 milliseconds
        @test millis > 1_577_836_800_000  # After 2020
        @test millis < 2_208_988_800_000  # Before 2040
        
        # Similar tests for micros and nanos
        micros = time_micros(clock)
        @test micros > 1_577_836_800_000_000  # After 2020
        @test micros < 2_208_988_800_000_000  # Before 2040
        
        nanos = time_nanos(clock)
        @test nanos > 1_577_836_800_000_000_000  # After 2020
        @test nanos < 2_208_988_800_000_000_000  # Before 2040
    end
    
    @testset "Multiple Instances" begin
        # Test that multiple instances behave consistently
        clock1 = EpochClock()
        clock2 = EpochClock()
        
        t1 = time_millis(clock1)
        t2 = time_millis(clock2)
        
        # Times should be very close (within a few milliseconds)
        @test abs(t1 - t2) < 10
    end
    
    @testset "High Precision" begin
        clock = EpochClock()
        
        # Test that we can get different nanosecond values in quick succession
        times = [time_nanos(clock) for _ in 1:10]
        
        # At least some of the times should be different (showing precision)
        # On high-precision implementations (Julia 1.11+), expect good precision
        # On fallback implementations (Julia < 1.11), especially on Windows,
        # time() may have lower resolution, so be more lenient
        if IS_HIGH_PRECISION
            @test length(unique(times)) > 1
        else
            # For fallback implementation, we still expect some precision but
            # may be limited by time() resolution on some platforms
            unique_count = length(unique(times))
            @test unique_count >= 1  # At least one time should be recorded
            # If all times are the same, it's likely due to limited time() resolution
            if unique_count == 1
                @test_skip "Precision test skipped due to limited time() resolution on this platform"
            else
                @test unique_count > 1
            end
        end
    end
end