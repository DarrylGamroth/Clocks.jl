@testset "System clocks" begin
    epoch = SystemEpochClock()
    epoch_micro = SystemEpochMicroClock()
    epoch_nano = SystemEpochNanoClock()
    nano = SystemNanoClock()

    @test epoch isa AbstractEpochClock
    @test epoch_micro isa AbstractEpochMicroClock
    @test epoch_nano isa AbstractEpochNanoClock
    @test nano isa AbstractNanoClock
    @test all(c -> c isa AbstractClock, (epoch, epoch_micro, epoch_nano, nano))

    @test sizeof(SystemEpochClock) == 0
    @test sizeof(SystemEpochMicroClock) == 0
    @test sizeof(SystemEpochNanoClock) == 0
    @test sizeof(SystemNanoClock) == 0

    @test @inferred(time_millis(epoch)) isa Int64
    @test @inferred(time_micros(epoch_micro)) isa Int64
    @test @inferred(time_nanos(epoch_nano)) isa Int64
    @test @inferred(time_nanos(nano)) isa Int64

    @test !applicable(time_micros, epoch)
    @test !applicable(time_nanos, epoch)
    @test !applicable(time_millis, epoch_micro)
    @test !applicable(time_millis, epoch_nano)
    @test !applicable(time_millis, nano)
    @test !applicable(time_micros, nano)

    samples = [time_nanos(nano) for _ in 1:1_000]
    @test issorted(samples)

    before = time_nanos(nano)
    sleep(0.005)
    after = time_nanos(nano)
    @test after > before
end
