using Base.Threads
using Base.Test
using Base.Threads.Atomic
using LightGraphs
using GraphBenchmarks
using BenchmarkTools
using JLD
using UnsafeAtomics

import Base: push!, shift!, isempty, getindex
import GraphBenchmarks: preparebench

include("lg.jl")

immutable ThreadQueue{T}
    data::Vector{T}
    head::Atomic{Int}
    tail::Atomic{Int}
end

abstract LGBFSAlgs <: AbstractBFS

immutable NaiveSerialBFS <: LGBFSAlgs end
immutable ParallBFS <: LGBFSAlgs end
immutable LevelSynchronous <: LGBFSAlgs end

function ThreadQueue(T::Type, maxlength::Int)
    q = ThreadQueue(Vector{T}(maxlength), Atomic{Int}(1), Atomic{Int}(1))
    return q
end

function push!{T}(q::ThreadQueue{T}, val::T)
    # TODO: check that head > tail
    offset = atomic_add!(q.tail, 1)
    q.data[offset] = val
    return offset
end

function shift!{T}(q::ThreadQueue{T})
    # TODO: check that head < tail
    offset = atomic_add!(q.head, 1)
    return q.data[offset]
end

function isempty(q::ThreadQueue)
    return ( q.head[] == q.tail[] ) && q.head != 1
    # return q.head == length(q.data)
end

function getindex{T}(q::ThreadQueue{T}, iter)
    return q.data[iter]
end

function bfs(alg::NaiveSerialBFS, next::Vector{Int}, g::SimpleGraph, source::Int64)
    parents = fill(-2, nv(g)) #Initialize parents array with -2's.
    parents[source]=-1 #Set source to -1
    while !isempty(next)
        src = shift!(next) #Get first element
        vertexneighbors = neighbors(g, src)
        for vertex in vertexneighbors
            #If not already set, and is not found in the queue.
            if parents[vertex]==-2
                push!(next, vertex) #Push onto queue
                parents[vertex] = src
            end
        end
    end
    return parents
end

function bfskernel(alg::ParallBFS, next::ThreadQueue, src::Int64, parents::Array{Int64}, vertexneighbors::Array{Int64})
    @threads for vertex in vertexneighbors
        #If not already set, and is not found in the queue.
        if parents[vertex]==-2
            # println("pushing: $vertex")
            push!(next, vertex) #Push onto queue
            # println("pushed: $vertex")
            parents[vertex] = src
        end
    end
end

function bfs(alg::ParallBFS, next::ThreadQueue, g::SimpleGraph, source::Int64, parents::Array{Int64})
    parents[source]=-1 #Set source to -1
    push!(next, source)
    while !isempty(next)
        src = shift!(next) #Get first element
        vertexneighbors = neighbors(g, src)
        bfskernel(alg, next, src, parents, vertexneighbors)
    end
    return parents
end

function bfskernel(alg::LevelSynchronous, next::ThreadQueue, g::SimpleGraph, parents::Array{Int64}, level::Array{Int64})
    @threads for src in level
        vertexneighbors = neighbors(g, src)
        for vertex in vertexneighbors
            #Set parent value if not set yet.
            parent = UnsafeAtomics.unsafe_atomic_cas!(parents, vertex, -2, src)
            if parent==-2
                push!(next, vertex) #Push onto queue
            end
        end
    end
end

function bfs(
        alg::LevelSynchronous, next::ThreadQueue, g::SimpleGraph, source::Int64,
        parents::Array{Int64}
    )
    parents[source]=-1 #Set source to -1
    push!(next, source)
    while !isempty(next)
        level = next[next.head[]:next.tail[]-1]
        next.head[] = next.tail[] #reset the queue
        bfskernel(alg, next, g, parents, level)
    end
    return parents
end

function bfs(alg::NaiveSerialBFS, g::SimpleGraph, source::Int, nv::Int)
    next = Vector{Int64}([source])
    sizehint!(next, nv)
    return bfs(NaiveSerialBFS(), next, g, source)
end

function bfs(alg::LevelSynchronous, g::SimpleGraph, source::Int64, nv::Int64)
    next = ThreadQueue(Int, nv)
    parents = fill(-2, nv)
    bfs(alg, next, g, source, parents)
end

function bfs(alg::ParallBFS, g::SimpleGraph, source::Int64, nv::Int64)
    next = ThreadQueue(Int, nv)
    parents = fill(-2, nv)
    bfs(alg, next, g, source, parents)
end

function preparebench(benchmark::GraphBenchmarkSpec, alg::LGBFSAlgs, lg::LGGraph)
    n = nv(lg.g)
    sources = picksources(benchmark, n)
    bfsbench = @benchmarkable begin
        for src in $sources
            bfs($alg, $(lg.g), src, $n)
        end
    end seconds=6000 samples=10
    bfsbench
end

function bfsbenchsuite{T <: SimpleGraph}(t::Type{T}, bench::GraphBenchmarkSpec, scale::Int, edgefactor::Int)
    srand(0)
    gen = Kronecker(scale, edgefactor)
    suite = BenchmarkGroup(["bfs", "lg"])
    suite["serial"] = BenchmarkGroup(["serialbfs"])
    suite["serial"]["lgbfs"] = preparebenchmark(bench, LGGraph{T}, BFS(), gen)
    suite["serial"]["naivebfs"] = preparebenchmark(bench, LGGraph{T}, NaiveSerialBFS(), gen)
    suite["parallel"] = BenchmarkGroup(["parallelbfs"])
    suite["parallel"]["parallbfs"] = preparebenchmark(bench, LGGraph{T}, ParallBFS(), gen)
    suite["parallel"]["levelsyncbfs"] = preparebenchmark(bench, LGGraph{T}, LevelSynchronous(), gen)
    suite
end

function comparebfs{T <: SimpleGraph}(t::Type{T}, bench::GraphBenchmarkSpec, scale::Int, edgefactor::Int)
    suite = bfsbenchsuite(T, bench, scale, edgefactor)
    run(suite, verbose=true)
end
#Taken from the LightGraphs BFS test
function istree(parents::Vector{Int}, maxdepth)
    flag = true
    for i in 1:maxdepth
        s = i
        depth = 0
        while parents[s] > 0 && parents[s] != s
            s = parents[s]
            depth += 1
            if depth > maxdepth
                return false
            end
        end
    end
    return flag
end

function testbfsalgs()
    gen = Kronecker(10, 16)
    lg = construct(LGGraph{DiGraph}, generate(gen))
    n = nv(lg.g)
    visitor = LightGraphs.TreeBFSVisitorVector(zeros(Int,n))
    LightGraphs.bfs_tree!(visitor, lg.g, 1)
    @test istree(visitor.tree, n)
    @test istree(bfs(NaiveSerialBFS(), lg.g, 1, n), n)
    @test istree(bfs(LevelSynchronous(), lg.g, 1, n), n)
    @test istree(bfs(ParallBFS(), lg.g, 1, n), n)
end
