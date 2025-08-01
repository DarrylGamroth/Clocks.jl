using Test
using Clocks

@testset "Clocks.jl Tests" begin
    include("test_epochclock.jl")
    include("test_monotonicclock.jl")
    include("test_cachedepochclock.jl")
    include("test_integration.jl")
end