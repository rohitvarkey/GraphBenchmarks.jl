module GraphBenchmarks

using BenchmarkTools

export benchmark, GraphGenerator, GraphAlgorithm, GraphBenchmarkSpec, GraphType,
       Graph500, BFS, AbstractBFS, construct, preparebench, picksources

abstract GraphGenerator
abstract GraphAlgorithm
abstract GraphBenchmarkSpec
abstract GraphType

abstract AbstractBFS <: GraphAlgorithm
immutable BFS <: AbstractBFS end

immutable Graph500 <: GraphBenchmarkSpec end

include("generators/kronecker.jl")

function benchmark{B <: GraphBenchmarkSpec, T <: GraphType, A <: GraphAlgorithm, G <: GraphGenerator}(
        benchmark::B,
        t::Type{T},
        alg::A,
        generator::G
    )
    bench = preparebenchmark(benchmark, t, alg, generator)
    trial = run(bench)
    trial
end

function construct{T <: GraphType}(t::Type{T}, edges::Array)
    error("Construct not defined for $(T)")
end

function preparebench{B <: GraphBenchmarkSpec, A <: GraphAlgorithm, T <: GraphType}(
    benchmark::B,
    alg::A,
    g::T
    )
    error("preparebench not defined for $(typeof(g))")
end

function preparebenchmark{B <: GraphBenchmarkSpec, T <: GraphType, A <: GraphAlgorithm, G <: GraphGenerator}(
        benchmark::B,
        t::Type{T},
        alg::A,
        generator::G
    )
    #Generate the edges to be added based on the generator. All generators should return a 2D Array with
    #the edges.
    edges = generate(generator)

    #construct a graph `g` of type `t` with the edges in `edges`
	g = construct(t, edges)

    #Alternatively, we could have `generate(t, generator)` that does both of these steps together.
    #Allows for the generator to not have to generate the entire edge list
    bench = preparebench(benchmark, alg, g)
    bench
end

function picksources(::Graph500, nv::Int64)
    srand(0)
    sources = rand(1:nv, 64)
end

end
