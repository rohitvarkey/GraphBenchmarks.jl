using BenchmarkTools
using JLD

include("stinger.jl")
include("parallelbfslg.jl")

function createsuite(bench::GraphBenchmarkSpec, scale::Int, edgefactor::Int)
    suite = BenchmarkGroup([])
    suite["lg"] = bfsbenchsuite(DiGraph, bench, scale, edgefactor)
    suite["stinger"] = bfsbenchsuite(StingerGraph, bench, scale, edgefactor)
    suite
end

function bench(bench::GraphBenchmarkSpec, scaleRange::Range{Int}, edgefactor::Int)
    benchname = split("$(typeof(bench))", '.')[end]
    suite = BenchmarkGroup([benchname])
    for scale in scaleRange
        suite["$(scale)_$(edgefactor)"] = createsuite(bench, scale, edgefactor)
    end
    threads = Threads.nthreads()
    info("Running the $benchname benchmarks for threads=$threads")
    results = run(suite)
    jldopen(joinpath(dirname(@__FILE__), "bfs_$threads.jld"), "w") do f
        write(f, "bfssuite_$(benchname)", results)
    end
end

bench(Graph500(), 10:12, 16)
