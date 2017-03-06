using GraphBenchmarks
using Base.Test

include(joinpath(Pkg.dir("GraphBenchmarks", "src", "examples"), "lg.jl"))
#include(joinpath(Pkg.dir("GraphBenchmarks", "src", "examples"), "stinger.jl"))
# write your own tests here
const benchmarkspecs = (Graph500(),)#(StingerBenchmarks(), Graph500())
for benchmarkspec in benchmarkspecs
    info("Running $benchmarkspec benchmarks")
    #= #Uncomment to run the StingerWrapper tests
    info("Running SerialBFS for StingerGraph")
    @test isa(benchmark(benchmarkspec, StingerGraph, SerialBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    info("Running LevelSynchronousBFS for StingerGraph")
    @test isa(benchmark(benchmarkspec, StingerGraph, LevelSynchronousBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    =#
    info("Running BFS for LightGraphs Graph")
    @test isa(benchmark(benchmarkspec, LGGraph{LightGraphs.Graph}, BFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    info("Running BFS for LightGraphs DiGraph")
    @test isa(benchmark(benchmarkspec, LGGraph{LightGraphs.DiGraph}, BFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
end
