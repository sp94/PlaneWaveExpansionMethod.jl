"""
    PlaneWaveBasis(b1::Vector{Float64}, b2::Vector{Float64},
            ps::Vector{Int}, qs::Vector{Int})

A 2D basis of plane waves, `ks = ps*b1 + qs*b2`.
"""
struct PlaneWaveBasis
    b1::Vector{Float64}
    b2::Vector{Float64}
    ps::Vector{Int}
    qs::Vector{Int}
    kxs::Vector{Float64}
    kys::Vector{Float64}
    function PlaneWaveBasis(b1::Vector{Float64}, b2::Vector{Float64},
                                        ps::Vector{Int}, qs::Vector{Int})
        kxs = [p*b1[1]+q*b2[1] for (p,q) in zip(ps,qs)]
        kys = [p*b1[2]+q*b2[2] for (p,q) in zip(ps,qs)]
        return new(b1, b2, ps, qs, kxs, kys)
    end
end


"""
    PlaneWaveBasis(geometry::Geometry, cutoff::Int)

Approximate a basis of plane waves truncated in a circle.

The circle has a diameter of `cutoff` Brillouin zones. Increasing the `cutoff`
will increase the number of plane waves leading to a more accurate solution.
It is assumed that `norm(b1) == norm(b2)`.
"""
function PlaneWaveBasis(geometry::Geometry, cutoff::Int)
    @assert isodd(cutoff)
    b1, b2 = as_to_bs(geometry.a1, geometry.a2)
    @assert norm(b1) ≈ norm(b2) # for now
    ps, qs = Int[], Int[]
    cutoff_radius = norm(b1) * cutoff / 2
    for p in -cutoff:cutoff, q in -cutoff:cutoff
        k = p*b1 + q*b2
        if norm(k) <= cutoff_radius
            push!(ps, p)
            push!(qs, q)
        end
    end
    return PlaneWaveBasis(b1, b2, ps, qs)
end


"""
    Solver(geometry::Geometry, cutoff_b1::Int, cutoff_b2::Int)

Approximate the geometry using a basis of plane waves truncated in a rhombus.

The rhombus has lengths `cutoff_b1` and `cutoff_b2` in the `b1` and `b2`
directions, respectively.
"""
function PlaneWaveBasis(geometry::Geometry, cutoff_b1::Int, cutoff_b2::Int)
    @assert isodd(cutoff_b1)
    @assert isodd(cutoff_b2)
    P = div(cutoff_b1, 2) # rounds down
    Q = div(cutoff_b2, 2) # rounds down
    ps = [p for p in -P:P for q in -Q:Q]
    qs = [q for p in -P:P for q in -Q:Q]
    b1, b2 = as_to_bs(geometry.a1, geometry.a2)
    return PlaneWaveBasis(b1, b2, ps, qs)
end


"""
    BrillouinZoneCoordinate(p::Float64, q::Float64, label::String="")

A labelled coordinate in the Brillouin zone.

The arguments `p` and `q` are the coefficients of reciprocal lattice vectors
`b1` and `b2`. The k-space coordinate, `k = p * b1 + q * b2`, is generated by
`get_k(coord::BrillouinZoneCoordinate, basis::PlaneWaveBasis)`. For example,
`BrillouinZoneCoordinate(0.5,0)` is on the edge of the first Brillouin zone.
"""
struct BrillouinZoneCoordinate
    p::Float64
    q::Float64
    label::String
    function BrillouinZoneCoordinate(p::Real, q::Real, label::String="")
        return new(p, q, label)
    end
end


"""
    get_k(coord::BrillouinZoneCoordinate, basis::PlaneWaveBasis)

Return the k-space coordinate of the `BrillouinZoneCoordinate` in a particular
`PlaneWaveBasis`, ie `k = p*b1 + q*b2`.
"""
function get_k(coord::BrillouinZoneCoordinate, basis::PlaneWaveBasis)
    return coord.p*basis.b1 + coord.q*basis.b2
end
