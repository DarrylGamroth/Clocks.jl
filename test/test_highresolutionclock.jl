function test_epoch_read(read_clock, units_per_second)
    before = time()
    value = read_clock()
    after = time()

    # Accommodate a wall-clock adjustment without embedding an expiration date.
    lower = floor(Int64, (min(before, after) - 1) * units_per_second)
    upper = ceil(Int64, (max(before, after) + 1) * units_per_second)
    @test lower <= value <= upper
end

@testset "High-resolution epoch functions" begin
    @test @inferred(epoch_millis()) isa Int64
    @test @inferred(epoch_micros()) isa Int64
    @test @inferred(epoch_nanos()) isa Int64

    test_epoch_read(epoch_millis, 1_000)
    test_epoch_read(epoch_micros, 1_000_000)
    test_epoch_read(epoch_nanos, 1_000_000_000)

    @static if VERSION >= v"1.11"
        # Exercise the libuv error adapter directly; a successful clock read
        # cannot naturally reach this path. Julia 1.10 uses the fallback file.
        @test_throws ErrorException Clocks.uv_clock_error(Cint(-1))
    end
end
