@testset "MonotonicClock Tests" begin
    @testset "Constructor" begin
        clock = MonotonicClock()
        @test clock isa MonotonicClock
        @test clock isa AbstractClock
    end
    
    @testset "Basic Functionality" begin
        clock = MonotonicClock()
        
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
        clock = MonotonicClock()
        
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
    
    @testset "Monotonic Property" begin
        clock = MonotonicClock()
        
        # Test that time never goes backwards (monotonic property)
        times_millis = Int64[]
        times_micros = Int64[]
        times_nanos = Int64[]
        
        for i in 1:20
            push!(times_millis, time_millis(clock))
            push!(times_micros, time_micros(clock))
            push!(times_nanos, time_nanos(clock))
            if i < 20
                sleep(0.001)  # Small delay between measurements
            end
        end
        
        # Check that each subsequent time is >= previous time
        for i in 2:length(times_millis)
            @test times_millis[i] >= times_millis[i-1]
            @test times_micros[i] >= times_micros[i-1]
            @test times_nanos[i] >= times_nanos[i-1]
        end
    end
    
    @testset "Time Progression" begin
        clock = MonotonicClock()
        
        # Test that time progresses over a longer interval
        t1_millis = time_millis(clock)
        sleep(0.01)  # Sleep 10ms
        t2_millis = time_millis(clock)
        @test t2_millis > t1_millis
        
        t1_micros = time_micros(clock)
        sleep(0.01)  # Sleep 10ms
        t2_micros = time_micros(clock)
        @test t2_micros > t1_micros
        
        t1_nanos = time_nanos(clock)
        sleep(0.01)  # Sleep 10ms
        t2_nanos = time_nanos(clock)
        @test t2_nanos > t1_nanos
    end
    
    @testset "Multiple Instances" begin
        # Test that multiple instances behave consistently
        clock1 = MonotonicClock()
        clock2 = MonotonicClock()
        
        t1 = time_millis(clock1)
        t2 = time_millis(clock2)
        
        # Times should be very close since they're based on the same underlying time_ns()
        @test abs(t1 - t2) < 10
    end
    
    @testset "Precision and Range" begin
        clock = MonotonicClock()
        
        # Test nanosecond precision
        times = [time_nanos(clock) for _ in 1:10]
        @test length(unique(times)) > 1  # Should get different values
        
        # Test that values are in reasonable range (not negative, not too large)
        nanos = time_nanos(clock)
        @test nanos > 0
        @test nanos < typemax(Int64) ÷ 2  # Should be well within Int64 range
    end
    
    @testset "Bit Masking" begin
        # Test the specific bit masking done in time_nanos
        # The implementation does: Int64(time_ns() & 0x7fffffffffffffff)
        clock = MonotonicClock()
        nanos = time_nanos(clock)
        
        # Should always be positive due to the bit masking (top bit cleared)
        @test nanos >= 0
        @test nanos == nanos & 0x7fffffffffffffff
    end
    
    @testset "Conversion Accuracy" begin
        clock = MonotonicClock()
        
        # Test that divisions are accurate
        nanos = time_nanos(clock)
        expected_micros = nanos ÷ 1_000
        expected_millis = nanos ÷ 1_000_000
        
        actual_micros = time_micros(clock)
        actual_millis = time_millis(clock)
        
        # Should be very close (allowing for timing differences)
        @test abs(actual_micros - expected_micros) <= 10
        @test abs(actual_millis - expected_millis) <= 10
    end
end