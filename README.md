# Clocks.jl

[![CI](https://github.com/DarrylGamroth/Clocks.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/DarrylGamroth/Clocks.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DarrylGamroth/Clocks.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/DarrylGamroth/Clocks.jl)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Clocks.jl provides allocation-free clock providers modeled on Agrona's clock
contracts and expressed with Julia's type system and multiple dispatch.

Each provider has one time domain and one unit:

| Contract | Abstract provider | Concrete providers | Read function |
|---|---|---|---|
| Unix epoch milliseconds | `AbstractEpochClock` | `SystemEpochClock`, `CachedEpochClock` | `time_millis` |
| Unix epoch microseconds | `AbstractEpochMicroClock` | `SystemEpochMicroClock`, `CachedEpochMicroClock` | `time_micros` |
| Unix epoch nanoseconds | `AbstractEpochNanoClock` | `SystemEpochNanoClock`, `OffsetEpochNanoClock`, `CachedEpochNanoClock` | `time_nanos` |
| Monotonic nanosecond ticks | `AbstractNanoClock` | `SystemNanoClock`, `CachedNanoClock` | `time_nanos` |

This separation prevents an arbitrary-origin monotonic value from being used
as an epoch timestamp. The zero-field system providers are immutable values;
constructing them does not allocate.

## System clocks

```julia
using Clocks

epoch_ms = time_millis(SystemEpochClock())
epoch_us = time_micros(SystemEpochMicroClock())
epoch_ns = time_nanos(SystemEpochNanoClock())

monotonic = SystemNanoClock()
start_ns = time_nanos(monotonic)
# work
elapsed_ns = time_nanos(monotonic) - start_ns
```

The direct `epoch_millis()`, `epoch_micros()`, and `epoch_nanos()` functions
provide the same high-resolution epoch sources without constructing a
provider value.

## Offset epoch nanoseconds

`OffsetEpochNanoClock` samples the relationship between epoch time and a
monotonic nanosecond clock, then uses the monotonic source on its normal read
path. It automatically resamples after one hour by default, or when the
monotonic source moves backwards:

```julia
offset_clock = OffsetEpochNanoClock()
epoch_ns = time_nanos(offset_clock)

sample!(offset_clock)               # Explicitly refresh the sampled offset
is_within_threshold(offset_clock)   # Did sampling meet the accuracy target?
```

The source clocks can be injected for testing or application-specific clock
providers. Configuration uses keyword arguments with explicit nanosecond
units:

```julia
offset_clock = OffsetEpochNanoClock(
    SystemEpochNanoClock(),
    SystemNanoClock();
    max_measurement_retries=100,
    measurement_threshold_ns=250,
    resample_interval_ns=3_600_000_000_000,
)
```

Unlike a direct realtime clock, this clock follows monotonic progression
between samples. A wall-clock adjustment becomes visible when the offset is
resampled.

## Cached clocks

Like Agrona's cached clocks, cached providers are manually driven. They do not
own or poll another clock:

```julia
epoch_source = SystemEpochClock()
cached_epoch = CachedEpochClock()
update!(cached_epoch, time_millis(epoch_source))
now_ms = time_millis(cached_epoch)
advance!(cached_epoch, 1)

epoch_nano_source = SystemEpochNanoClock()
cached_epoch_nano = CachedEpochNanoClock()
update!(cached_epoch_nano, time_nanos(epoch_nano_source))
now_epoch_ns = time_nanos(cached_epoch_nano)

nano_source = SystemNanoClock()
cached_nano = CachedNanoClock()
update!(cached_nano, time_nanos(nano_source))
now_ns = time_nanos(cached_nano)
```

A cached clock has a single updating owner and any number of readers. Updates
are published with release ordering and observed with acquire ordering. An
`advance!` is intentionally a single-writer operation, not a multi-writer
atomic increment.

The cached value is isolated by a conservative 128-byte pad on each side.
This covers common 64-byte and 128-byte cache lines without performing native
topology discovery or adding a runtime dependency.

## Migrating from 0.2

- Choose `SystemEpochClock`, `SystemEpochMicroClock`, or
  `SystemEpochNanoClock` based on the required epoch unit.
- Replace `MonotonicClock()` with `SystemNanoClock()`.
- Replace `CachedMonotonicClock(source)` with `CachedNanoClock()` and call
  `update!` from the owning agent.
- Construct `CachedEpochClock()` without a source and update it in
  milliseconds.
- `fetch!` was removed; source refresh policy belongs to the owning agent.

## License

Clocks.jl is licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
Portions of the clock-provider design and implementation are adapted from
[Agrona](https://github.com/aeron-io/agrona), copyright Real Logic Limited.
See [LICENSE](LICENSE) and [NOTICE](NOTICE) for details.
