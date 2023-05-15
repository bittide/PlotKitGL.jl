
module Runtests
using PlotKitCairo
using PlotKitAxes
using PlotKitGL
using Test
include("testset.jl")
end

using .Runtests
Runtests.main()


