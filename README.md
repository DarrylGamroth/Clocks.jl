# Clocks.jl

This package provides different clock implementations for Julia.

## Usage

```julia
using Clocks

# Epoch Clock
e = EpochClock()
millis = time_millis(e)
micros = time_micros(e)
nanos = time_nanos(e)

# Cached Epoch Clock
c = CachedEpochClock()
fetch!(cached_clock, e) # Initialize the cached clock with the current time from an EpochClock
cached_millis = time_millis(c)
cached_micros = time_micros(c)
cached_nanos = time_nanos(c)
advance!(cached_clock, 1_000_000) # Advance the cached clock by 1ms
update!(cached_clock, nanos) # Update the cached clock to a previously obtained value 

# Monotonic Clock
m = MonotonicClock()
monotonic_millis = time_millis(m)
monotonic_micros = time_micros(m)
monotonic_nanos = time_nanos(m)