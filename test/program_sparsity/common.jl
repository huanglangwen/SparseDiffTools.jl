### Rules
using Cassette
using SparseArrays
import Cassette: tag, untag, Tagged, metadata, hasmetadata, istagged
using SparseDiffTools
import SparseDiffTools: Path, BranchesPass, SparsityContext, Fixed,
                        Input, Output, ProvinanceSet, Tainted, istainted,
                        alldone, reset!

function tester(f, Y, X, args...; sparsity=Sparsity(length(Y), length(X)))

    path = Path()
    ctx = SparsityContext(metadata=(sparsity, path), pass=BranchesPass)
    ctx = Cassette.enabletagging(ctx, f)
    ctx = Cassette.disablehooks(ctx)

    val = nothing
    while true
        val = Cassette.overdub(ctx,
                            f,
                            tag(Y, ctx, Output()),
                            tag(X, ctx, Input()),
                            map(arg -> arg isa Fixed ?
                                arg.value :
                                tag(arg, ctx, ProvinanceSet(())), args)...)
        println("Explored path: ", path)
        alldone(path) && break
        reset!(path)
    end
    return ctx, val
end

testmeta(args...) = tester(args...)[1].metadata
testval(args...) = tester(args...) |> ((ctx,val),) -> untag(val, ctx)
testtag(args...) = tester(args...) |> ((ctx,val),) -> metadata(val, ctx)

using Test

Base.show(io::IO, ::Type{<:Cassette.Context}) = print(io, "ctx")
Base.show(io::IO, ::Type{<:Tagged}) = print(io, "tagged")

import Base.Broadcast: broadcasted, materialize, instantiate, preprocess
