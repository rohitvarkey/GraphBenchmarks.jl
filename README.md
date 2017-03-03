# GraphBenchmarks

[![Build Status](https://travis-ci.org/rohitvarkey/GraphBenchmarks.jl.svg?branch=master)](https://travis-ci.org/rohitvarkey/GraphBenchmarks.jl)

[![Coverage Status](https://coveralls.io/repos/rohitvarkey/GraphBenchmarks.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rohitvarkey/GraphBenchmarks.jl?branch=master)

[![codecov.io](http://codecov.io/github/rohitvarkey/GraphBenchmarks.jl/coverage.svg?branch=master)](http://codecov.io/github/rohitvarkey/GraphBenchmarks.jl?branch=master)

GraphBenchmarks is aimed at providing a package to be able to write benchmarks
for Graph libraries in Julia easily. It provides interfaces that can be specialized
on by Graph libraries and allow for easily switching between benchmark specifications,
graph representation, graph algorithms and input graph generators.

### Motivation

The idea behind this package is to be able to perform a workflow such as
```julia
using GraphBenchmarks
using StingerWrapper, LightGraphs
levelsyncstinger = benchmark(Graph500(), StingerGraph, LevelSynchronousBFS(), Kronecker(15, 16))
serialstinger = benchmark(Graph500(), StingerGraph, SerialBFS(), Kronecker(15, 16))
seriallightgraphs = benchmark(Graph500(), LGGraph{DiGraph}, BFS(), Kronecker(15, 16))

judge(minimum(levelsyncstinger),minimum(serialstinger))
judge(minimum(serialstinger),minimum(seriallightgraphs))
judge(minimum(levelsyncstinger),minimum(seriallightgraphs))
```

### The `benchmark` function

The `benchmark` function is the core function of the package which is
```julia
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
    g = construct(t, edges)
    #Run the benchmark
    trial = runbench(benchmark, alg, g)
end
```

### The abstract types
Users can create subtypes of the each of the abstract types for the following usecases:

- `GraphBenchmarkSpec` - Allows to specify a benchmark specification. For example,
the `Graph500` benchmark picks 64 random vertices as sources for a BFS. A benchmark I
use in StingerWrapper.jl was to pick the first 1000. I could just define a
`StingerBenchmark` type that allowed me to choose the sources I wanted. Similarly,
other benchmark specifications can be implemented.
- `GraphType` - Users can define their graph representation type as a subtype of
`GraphType` and define a `construct` method which constructs the graph representation given an `Array` of edges.
- `GraphAlgorithm` - This decides the algorithm to be run. Mostly a stub to help on
dispatch but can be used to encode parameters required for an algorithm.
- `GraphGenerator` - Create a generator. Generators must implement a `generate` method that
returns the edge array. See the example `Kronecker` [generator](src/generators/kronecker.jl).

### Defining the benchmark

A `runbench` method that takes the benchmark specifications, the algorithm to be used
and the graph type should return a `BenchmarkTools.Trial`. Ideally, the package should
provide a macro to replace `@benchmarkable` and assign parameters to it that have been
configured in the package.

### Examples

See [LightGraphs](src/examples/lg.jl) and [StingerWrapper](src/examples/stinger.jl) as examples
on using the interface and the [tests](test/runtests.jl) to see an example workflow.

*NOTE: This is a prototype and the interface is subject to change.*
