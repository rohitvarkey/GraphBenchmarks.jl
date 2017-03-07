using StingerWrapper
using BenchmarkTools
using GraphBenchmarks
import GraphBenchmarks: construct, preparebench, picksources

import StingerWrapper: bfs

export StingerGraph, SerialBFS, LevelSynchronousBFS, StingerBenchmarks

immutable StingerGraph <: GraphType
    s::Stinger
    nv::Int64
end

immutable StingerBenchmarks <: GraphBenchmarkSpec end

immutable SerialBFS <: AbstractBFS end
immutable LevelSynchronousBFS <: AbstractBFS end

function construct(t::Type{StingerGraph}, edges::Array{Int64, 2})
    s = Stinger()
    for i=1:size(edges,2)
        insert_edge!(s, 0, edges[1, i]-1, edges[2, i]-1, 0, 0)
    end
    StingerGraph(s, maximum(edges)) #max number of active vertices
end

function picksources(::StingerBenchmarks, nv::Int64)
    sources = collect(1:1000)
end

function preparebench(benchmark::GraphBenchmarkSpec, alg::SerialBFS, g::StingerGraph)
    sources = picksources(benchmark, g.nv) - 1
    bfsbench = @benchmarkable begin
        for src in $sources
            StingerWrapper.bfs($(g.s), src, $(g.nv))
        end
    end seconds=6000 samples=10
    bfsbench
end

function preparebench(benchmark::GraphBenchmarkSpec, alg::LevelSynchronousBFS, g::StingerGraph)
    sources = picksources(benchmark, g.nv) - 1
    bfsbench = @benchmarkable begin
        for src in $sources
            StingerWrapper.bfs(StingerWrapper.LevelSynchronous(), $(g.s), src, $(g.nv))
        end
    end seconds=6000 samples=10
    bfsbench
end

function bfsbenchsuite(T::Type{StingerGraph}, bench::GraphBenchmarkSpec, scale::Int, edgefactor::Int)
    srand(0)
    gen = Kronecker(scale, edgefactor)
    suite = BenchmarkGroup(["bfs", "stinger"])
    suite["serial"] = BenchmarkGroup(["serialbfs"])
    suite["serial"]["stingerserialbfs"] = preparebenchmark(bench, T, SerialBFS(), gen)
    suite["parallel"] = BenchmarkGroup(["parallelbfs"])
    suite["parallel"]["levelsyncbfs"] = preparebenchmark(bench, T, LevelSynchronousBFS(), gen)
    suite
end

function comparebfs(T::Type{StingerGraph}, bench::GraphBenchmarkSpec, scale::Int, edgefactor::Int)
    suite = bfsbenchsuite(T, bench, scale, edgefactor)
    run(suite, verbose=true)
end
