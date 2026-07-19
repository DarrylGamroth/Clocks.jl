# Copyright 2025-2026 Rubus Technologies Inc.
# SPDX-License-Identifier: Apache-2.0

using Test
using Clocks

@testset "Clocks.jl" begin
    include("test_highresolutionclock.jl")
    include("test_systemclocks.jl")
    include("test_offsetepochnanoclock.jl")
    include("test_cachedclocks.jl")
    include("test_integration.jl")
end
