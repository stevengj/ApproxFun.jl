export discretize,timedirichlet

include("OperatorSchur.jl")
include("KroneckerOperator.jl")

include("factorizations.jl")
include("pdesolve.jl")
include("kron.jl")

## PDE

function lap(d::Union(ProductDomain,TensorSpace))
    @assert length(d)==2
    Dx=Derivative(d[1])
    Dy=Derivative(d[2])
    Dx^2⊗I+I⊗Dy^2
end

Derivative(d::Union(ProductDomain,TensorSpace),k::Integer)=k==1?Derivative(d[1])⊗I:I⊗Derivative(d[2])

grad(d::ProductDomain)=[Derivative(d,k) for k=1:length(d.domains)]



for op in (:dirichlet,:neumann,:diffbcs)
    @eval begin
        function $op(d::Union(ProductDomain,TensorSpace),k...)
            @assert length(d)==2
            Bx=$op(d[1],k...)
            By=$op(d[2],k...)
            if isempty(Bx)
                I⊗By
            elseif isempty(By)
                Bx⊗I
            else
                [Bx⊗I;I⊗By]
            end
        end
    end
end


function timedirichlet(d::Union(ProductDomain,TensorSpace))
    @assert length(d.domains)==2
    Bx=dirichlet(d.domains[1])
    Bt=dirichlet(d.domains[2])[1]
    [I⊗Bt;Bx⊗I]
end



*(B::Functional,f::ProductFun)=Fun(map(c->B*c,f.coefficients),space(f,2))
*(B::BandedOperator,f::ProductFun)=ProductFun(map(c->B*c,f.coefficients),space(f))

*(f::ProductFun,B::Operator)=B*(f.')
