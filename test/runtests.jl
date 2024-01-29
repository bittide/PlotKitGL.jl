
#
# run using Pkg.test("PlotKitGL")
#
#
# or using
#
#  cd PlotKitGL.jl/test
#  julia
#  include("runtests.jl")
#
#
#

module Runtests
using PlotKitCairo
using PlotKitAxes
using PlotKitGL
using Test
include("testset.jl")
end

using .Runtests
Runtests.main()


