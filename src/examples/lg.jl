using LightGraphs
using GraphBenchmarks
import GraphBenchmarks: construct, preparebench
using BenchmarkTools

export LGGraph, construct

immutable LGGraph{T<:SimpleGraph} <: GraphType
    g::T
end

function construct{T <: SimpleGraph}(t::Type{LGGraph{T}}, edges::Array{Int64, 2})
    g = T(size(edges, 2))
    for i=1:size(edges,2)
        add_edge!(g, edges[1, i], edges[2, i])
    end
    LGGraph(g)
end

function preparebench(benchmark::GraphBenchmarkSpec, alg::BFS, lg::LGGraph)
    n = nv(lg.g)
    sources = picksources(benchmark, n)
    visitor = LightGraphs.TreeBFSVisitorVector(zeros(Int,n))
    bfsbench = @benchmarkable begin
        for src in $sources
            LightGraphs.bfs_tree!($visitor, $(lg.g), src)
        end
    end seconds=6000 samples=10
    bfsbench
end
