export Kronecker

immutable Kronecker <: GraphGenerator
	scale::Int64
	edgefactor::Int64
    a::Float64
    b::Float64
    c::Float64

    function Kronecker(
        scale::Int64,
        edgefactor::Int64;
        a::Float64=0.57,
        b::Float64=0.19,
        c::Float64 = 0.19
        )
        new(scale, edgefactor, a, b, c)
    end
end

function generate(generator::Kronecker)
    #Ported from https://gitorious.org/graph500/graph500?p=graph500:graph500.git;a=blob;f=octave/kronecker_generator.m;h=064b6d4f42194cc95ec4ab375dcbee7c3243b233;hb=01a32a9c16994c3cf30bbf4caabf9be128379416.
    n = 2 ^ generator.scale
    m = generator.edgefactor * n
    ij = ones(Int64, 2, m)
    ab = generator.a + generator.b
    cnorm = generator.c/(1-ab)
    anorm = generator.a/ab

    for ib in 1:generator.scale
        ii_bit = rand(1, m) .> ab
        jj_bit = rand(1, m) .> ( cnorm * ii_bit + anorm * !(ii_bit) )
        ij = ij .+ 2^(ib-1) .* [ii_bit; jj_bit]
    end

    p = randperm(n)
    ij = p[ij]

    p = randperm(m)
    ij = ij[:, p]

    return ij
end
