# DirichletSpaces

export ChebyshevDirichlet

immutable ChebyshevDirichlet{left,right} <: PolynomialSpace
    domain::Interval
    ChebyshevDirichlet(d)=new(d)
    ChebyshevDirichlet()=new(Interval())
end

spacescompatible{l,r}(a::ChebyshevDirichlet{l,r},b::ChebyshevDirichlet{l,r})=domainscompatible(a,b)

ChebyshevDirichlet()=ChebyshevDirichlet{1,1}()
ZeroChebyshevDirichlet(d)=SliceSpace(ChebyshevDirichlet{1,1}(d),2)
ZeroChebyshevDirichlet()=SliceSpace(ChebyshevDirichlet{1,1}(),2)

canonicalspace(S::ChebyshevDirichlet)=Chebyshev(domain(S))


## coefficients

# converts to f_0 T_0 + f_1 T_1 +  \sum f_k (T_k - T_{k-2})

function dirichlettransform!(w::Vector)
    for k=length(w)-2:-1:1
        @inbounds w[k] += w[k+2]
    end

    w
end

function idirichlettransform!(w::Vector)
    for k=3:length(w)
        @inbounds w[k-2]-= w[k]
    end

    w
end


# converts to f_0 T_0 + \sum f_k (T_k ± T_{k-1})

function idirichlettransform!(s::Bool,w::Vector)
    for k=2:length(w)
        @inbounds w[k-1]+= (s?-1:1)*w[k]
    end

    w
end


function dirichlettransform!(s::Bool,w::Vector)
    for k=length(w)-1:-1:1
        @inbounds w[k] += (s?1:-1)*w[k+1]
    end

    w
end



coefficients(v::Vector,::Chebyshev,::ChebyshevDirichlet{1,1})=dirichlettransform!(copy(v))
coefficients(v::Vector,::Chebyshev,::ChebyshevDirichlet{0,1})=dirichlettransform!(true,copy(v))
coefficients(v::Vector,::Chebyshev,::ChebyshevDirichlet{1,0})=dirichlettransform!(false,copy(v))

coefficients(v::Vector,::ChebyshevDirichlet{1,1},::Chebyshev)=idirichlettransform!(copy(v))
coefficients(v::Vector,::ChebyshevDirichlet{0,1},::Chebyshev)=idirichlettransform!(true,copy(v))
coefficients(v::Vector,::ChebyshevDirichlet{1,0},::Chebyshev)=idirichlettransform!(false,copy(v))

## Dirichlet Conversion operators

addentries!(C::Conversion{ChebyshevDirichlet{1,0},Chebyshev},A,kr::Range)=toeplitz_addentries!([],[1.,1.],A,kr)
addentries!(C::Conversion{ChebyshevDirichlet{0,1},Chebyshev},A,kr::Range)=toeplitz_addentries!([],[1.,-1.],A,kr)
function addentries!(C::Conversion{ChebyshevDirichlet{1,1},Chebyshev},A,kr::Range)
    A=toeplitz_addentries!([],[1.,0.,-1.],A,kr)

    A
end
function addentries!(C::Conversion{ChebyshevDirichlet{2,2},Chebyshev},A,kr::Range)
    for k=kr
        A[k,k]=1
        A[k,k+4]=2*(k+1)/k-1
        if k>= 3
            A[k,k+2]=-2*(k-1)/(k-2)
        end
    end

    A
end
bandinds(::Conversion{ChebyshevDirichlet{1,0},Chebyshev})=0,1
bandinds(::Conversion{ChebyshevDirichlet{0,1},Chebyshev})=0,1
bandinds(::Conversion{ChebyshevDirichlet{1,1},Chebyshev})=0,2

conversion_rule(b::ChebyshevDirichlet,a::Chebyshev)=b

# return the space that has banded Conversion to the other
# function conversion_rule(a::ChebyshevDirichlet,b::Ultraspherical)
#     @assert domainscompatible(a,b)
#
#     a
# end




## Evaluation Functional


datalength(B::Evaluation{ChebyshevDirichlet{1,0},Bool})=B.x?Inf:1
datalength(B::Evaluation{ChebyshevDirichlet{0,1},Bool})=B.x?1:Inf
datalength(B::Evaluation{ChebyshevDirichlet{1,1},Bool})=B.x?1:2

function getindex(B::Evaluation{ChebyshevDirichlet{1,0},Bool},kr::Range)
    d = domain(B)

    if B.x == false && B.order == 0
        Float64[k==1?1.0:0.0 for k=kr]
    elseif B.x == true && B.order == 0
        Float64[k==1?1.0:2.0 for k=kr]
    else
        getindex(Evaluation(d,B.x,B.order)*Conversion(domainspace(B)),kr)
    end
end

function getindex(B::Evaluation{ChebyshevDirichlet{0,1},Bool},kr::Range)
    d = domain(B)

    if B.x == true && B.order == 0
        Float64[k==1?1.0:0.0 for k=kr]
    elseif B.x == false && B.order == 0
        Float64[k==1?1.0:-(-1)^k*2.0 for k=kr]
    else
        getindex(Evaluation(d,B.x,B.order)*Conversion(domainspace(B)),kr)
    end
end

function getindex(B::Evaluation{ChebyshevDirichlet{1,1},Bool},kr::Range)
    d = domain(B)

    if B.x == false && B.order == 0
        Float64[k==1?1.0:(k==2?-1.0:0.0) for k=kr]
    elseif B.x == true && B.order == 0
        Float64[k==1||k==2?1.0:0.0 for k=kr]
    else
        getindex(Evaluation(d,B.x,B.order)*Conversion(domainspace(B)),kr)
    end
end

Evaluation(sp::ChebyshevDirichlet,x::Float64,ord::Integer)=EvaluationWrapper(sp,x,ord,Evaluation(domain(sp),x,ord)*Conversion(sp))
