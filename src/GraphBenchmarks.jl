module GraphBenchmarks

using BenchmarkTools

export benchmark, GraphGenerator, GraphAlgorithm, GraphBenchmarkSpec, GraphType, Graph500, BFS

abstract GraphGenerator
abstract GraphAlgorithm
abstract GraphBenchmarkSpec
abstract GraphType

abstract BFS <: GraphAlgorithm

immutable Graph500 <: GraphBenchmarkSpec end

include("generators/kronecker.jl")
include("stinger.jl")

function benchmark{B <: GraphBenchmarkSpec, T <: GraphType, A <: GraphAlgorithm, G <: GraphGenerator}(
        benchmark::B,
        t::Type{T},
        alg::A,
        generator::G
    )
    #Generate the edges to be added based on the generator. All generators should return a 2D Array with
    #the edges.
    edges = generate(generator)

    #construct a graph `g` of type `t` with the edges in `edges`
	g = construct(t, edges) #This returns the graph representation - eg. Stinger or LG.Graph

    #Alternatively, we could have `generate(t, generator)` that does both of these steps together.
    #Allows for the generator to not have to generate the entire edge list

    trial = runbench(benchmark, alg, g)
    @show minimum(trial)
    trial
end

function picksources(::Graph500, alg::BFS, g::GraphType)
    srand(0)
    sources = rand(1:g.nv, 64)
end

end
