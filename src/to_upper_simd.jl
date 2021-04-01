module to_upper_simd

using BenchmarkTools, LoopVectorization, Random

function to_upper(s)
    ty = codeunit(s)
    b = Base.unsafe_wrap(Vector{ty}, Base.unsafe_convert(Ptr{ty}, s), ncodeunits(s))
    @inbounds for i in 1:length(b)
        is_lower = (b[i] >= convert(UInt8, 'a')) & (b[i] <= convert(UInt8, 'z'))
        if is_lower
            b[i] -= 0x20
        end
    end
    s
end

function to_upper_branchless(s)
    ty = codeunit(s)
    b = Base.unsafe_wrap(Vector{ty}, Base.unsafe_convert(Ptr{ty}, s), ncodeunits(s))
    @inbounds for i ∈ eachindex(b)
        is_lower = (b[i] >= convert(UInt8, 'a')) & (b[i] <= convert(UInt8, 'z'))
        b[i] -= is_lower * 0x20
    end
    s
end

function to_upper_avx(s)
    ty = codeunit(s)
    b = Base.unsafe_wrap(Vector{ty}, Base.unsafe_convert(Ptr{ty}, s), ncodeunits(s))
    a = convert(UInt8, 'a')
    z = convert(UInt8, 'z')
    @inbounds @avx for i ∈ eachindex(b)
        is_lower = (b[i] >= a) & (b[i] <= z)
        b[i] -= is_lower * 0x20
    end
    s
end

function test()
    @assert to_upper("asAS") == "ASAS"
    @assert to_upper_branchless("asAS") == "ASAS"
    @assert to_upper_avx("asAS") == "ASAS"
end

test()

function bench() 
    display(@benchmark to_upper(s) setup=(s=randstring(100000)))
    display(@benchmark to_upper_branchless(s) setup=(s=randstring(100000)))
    display(@benchmark to_upper_avx(s) setup=(s=randstring(100000)))
end

bench()

end # module
