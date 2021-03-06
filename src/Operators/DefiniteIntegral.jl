export DefiniteIntegral,DefiniteLineIntegral

macro calculus_functional(Func)
    return esc(quote
        immutable $Func{S,T} <: Functional{T}
            domainspace::S
        end

        # We expect the operator to be real/complex if the basis is real/complex
        $Func()=$Func(UnsetSpace())
        $Func(dsp::FunctionSpace) = $Func{typeof(dsp),eltype(dsp)}(dsp)
        $Func(d::Domain) = $Func(Space(d))

        promotedomainspace(::$Func,sp::FunctionSpace)=$Func(sp)

        Base.convert{T}(::Type{Functional{T}},Σ::$Func)=$Func{typeof(Σ.domainspace),T}(Σ.domainspace)

        domain(Σ::$Func)=domain(Σ.domainspace)
        domainspace(Σ::$Func)=Σ.domainspace

        getindex(::$Func{UnsetSpace},kr::Range)=error("Spaces cannot be inferred for operator")

    end)
end

@calculus_functional(DefiniteIntegral)
@calculus_functional(DefiniteLineIntegral)


#default implementation
function getindex(B::DefiniteIntegral,kr::Range)
    S=domainspace(B)
    Q=Integral(S)
    A=(Evaluation(S,true)-Evaluation(S,false))*Q
    A[kr]
end