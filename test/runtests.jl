using Test
using Clocks

# Helper function to detect if we're using high-precision LibUV implementation
const IS_HIGH_PRECISION = VERSION >= v"1.11"

@testset "Clocks.jl Tests" begin
    include("test_epochclock.jl")
    include("test_monotonicclock.jl")
    include("test_cachedepochclock.jl")
    include("test_integration.jl")
end