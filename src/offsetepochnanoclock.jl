const DEFAULT_MAX_MEASUREMENT_RETRIES::Int = 100
const DEFAULT_MEASUREMENT_THRESHOLD_NS::Int64 = 250
const DEFAULT_RESAMPLE_INTERVAL_NS::Int64 = 3_600_000_000_000

"""
    OffsetEpochNanoClock(
        [epoch_clock=SystemEpochNanoClock()],
        [nano_clock=SystemNanoClock()];
        max_measurement_retries=100,
        measurement_threshold_ns=250,
        resample_interval_ns=3_600_000_000_000,
    )

Provider of epoch nanoseconds derived from a sampled offset between an epoch
clock and a monotonic nanosecond clock. The normal read path is allocation-free
and does not lock. The offset is resampled when the monotonic source moves
backwards or the resampling interval expires.

Instances are safe for concurrent readers and calls to [`sample!`](@ref) when
their source clocks are also safe for concurrent reads. Clock sources are
concrete type parameters, so custom providers can be injected without runtime
dispatch.
"""
mutable struct OffsetEpochNanoClock{
    E<:AbstractEpochNanoClock,
    N<:AbstractNanoClock,
} <: AbstractEpochNanoClock
    const epoch_clock::E
    const nano_clock::N
    const max_measurement_retries::Int
    const measurement_threshold_ns::Int64
    const resample_interval_ns::Int64
    @atomic epoch_offset_ns::Int64
    @atomic sample_nano_time::Int64
    @atomic within_threshold::Bool
    const sample_lock::ReentrantLock
end

OffsetEpochNanoClock(; kwargs...) =
    OffsetEpochNanoClock(SystemEpochNanoClock(), SystemNanoClock(); kwargs...)

OffsetEpochNanoClock(epoch_clock::AbstractEpochNanoClock; kwargs...) =
    OffsetEpochNanoClock(epoch_clock, SystemNanoClock(); kwargs...)

function OffsetEpochNanoClock(
    epoch_clock::E,
    nano_clock::N;
    max_measurement_retries::Integer=DEFAULT_MAX_MEASUREMENT_RETRIES,
    measurement_threshold_ns::Integer=DEFAULT_MEASUREMENT_THRESHOLD_NS,
    resample_interval_ns::Integer=DEFAULT_RESAMPLE_INTERVAL_NS,
) where {E<:AbstractEpochNanoClock,N<:AbstractNanoClock}
    retries = Int(max_measurement_retries)
    threshold_ns = Int64(measurement_threshold_ns)
    interval_ns = Int64(resample_interval_ns)

    retries > 0 || throw(ArgumentError("max_measurement_retries must be positive"))
    threshold_ns >= 0 || throw(ArgumentError("measurement_threshold_ns must be non-negative"))
    interval_ns > 0 || throw(ArgumentError("resample_interval_ns must be positive"))

    clock = OffsetEpochNanoClock{E,N}(
        epoch_clock,
        nano_clock,
        retries,
        threshold_ns,
        interval_ns,
        0,
        0,
        false,
        ReentrantLock(),
    )
    return sample!(clock)
end

"""
    sample!(clock::OffsetEpochNanoClock)

Resample the relationship between the epoch and monotonic sources. Up to
`max_measurement_retries` samples are taken. The first sample narrower than
`measurement_threshold_ns` is published; otherwise the narrowest sample is
used and [`is_within_threshold`](@ref) returns `false`.
"""
function sample!(clock::OffsetEpochNanoClock)
    lock(clock.sample_lock)
    try
        return _sample_unlocked!(clock)
    finally
        unlock(clock.sample_lock)
    end
end

function _sample_unlocked!(clock::OffsetEpochNanoClock)
    best_epoch_ns = Int64(0)
    best_nano_time = Int64(0)
    best_window_ns = typemax(Int64)
    within_threshold = false

    for _ in 1:clock.max_measurement_retries
        first_nano_time = time_nanos(clock.nano_clock)
        epoch_ns = time_nanos(clock.epoch_clock)
        second_nano_time = time_nanos(clock.nano_clock)
        window_ns = second_nano_time - first_nano_time

        if 0 <= window_ns < best_window_ns
            midpoint_ns = first_nano_time + (window_ns >> 1)
            best_epoch_ns = epoch_ns
            best_nano_time = midpoint_ns
            best_window_ns = window_ns

            if window_ns < clock.measurement_threshold_ns
                within_threshold = true
                break
            end
        end
    end

    best_window_ns != typemax(Int64) ||
        throw(ArgumentError("monotonic clock moved backwards during every sampling attempt"))

    epoch_offset_ns = best_epoch_ns - best_nano_time

    # Publish the sample time last. An acquire read of a new sample time then
    # observes the offset and diagnostic flag written before this release.
    @atomic :release clock.epoch_offset_ns = epoch_offset_ns
    @atomic :release clock.within_threshold = within_threshold
    @atomic :release clock.sample_nano_time = best_nano_time
    return clock
end

"""
    is_within_threshold(clock::OffsetEpochNanoClock)

Return whether the published sample met the configured measurement threshold.
"""
@inline is_within_threshold(clock::OffsetEpochNanoClock) =
    @atomic :acquire clock.within_threshold

@inline function time_nanos(clock::OffsetEpochNanoClock)
    sample_nano_time = @atomic :acquire clock.sample_nano_time
    nano_time = time_nanos(clock.nano_clock)
    adjustment_ns = nano_time - sample_nano_time

    if adjustment_ns < 0 || adjustment_ns > clock.resample_interval_ns
        return _resample_and_read(clock, sample_nano_time)
    end

    epoch_offset_ns = @atomic :acquire clock.epoch_offset_ns
    return nano_time + epoch_offset_ns
end

@noinline function _resample_and_read(
    clock::OffsetEpochNanoClock,
    observed_sample_nano_time::Int64,
)
    _resample_if_needed!(clock, observed_sample_nano_time)
    nano_time = time_nanos(clock.nano_clock)
    epoch_offset_ns = @atomic :acquire clock.epoch_offset_ns
    return nano_time + epoch_offset_ns
end

function _resample_if_needed!(
    clock::OffsetEpochNanoClock,
    observed_sample_nano_time::Int64,
)
    lock(clock.sample_lock)
    try
        current_sample_nano_time = @atomic :acquire clock.sample_nano_time
        if current_sample_nano_time == observed_sample_nano_time
            _sample_unlocked!(clock)
        end
    finally
        unlock(clock.sample_lock)
    end
    return nothing
end
