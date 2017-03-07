using BenchmarkTools

include("stinger.jl")
include("parallelbfslg.jl")

function createsuite(bench, scale, edgefactor)
    suite = BenchmarkGroup([])
    suite["lg"] = bfsbenchsuite(DiGraph, bench, scale, edgefactor)
    suite["stinger"] = bfsbenchsuite(StingerGraph, bench, scale, edgefactor)
    suite
end
