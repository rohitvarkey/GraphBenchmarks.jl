using GraphBenchmarks
using Base.Test

# write your own tests here
const benchmarkspecs = (StingerBenchmarks(), Graph500())
for benchmarkspec in benchmarkspecs
    info("Running $benchmarkspec benchmarks")
    info("Running SerialBFS for StingerGraph")
    @test isa(benchmark(benchmarkspec, StingerGraph, SerialBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    info("Running LevelSynchronousBFS for StingerGraph")
    @test isa(benchmark(benchmarkspec, StingerGraph, LevelSynchronousBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    info("Running BFS for LightGraphs Graph")
    @test isa(benchmark(benchmarkspec, LGGraph{LightGraphs.Graph}, SerialBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
    info("Running BFS for LightGraphs DiGraph")
    @test isa(benchmark(benchmarkspec, LGGraph{LightGraphs.DiGraph}, SerialBFS(), Kronecker(10, 16)), BenchmarkTools.Trial)
end
