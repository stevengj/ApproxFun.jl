## abs


function splitatroots(f::Fun)
    d=domain(f)

    pts=roots(f)

    if isempty(pts)
        f
    else
        da=first(d)
        isapprox(da,pts[1]) ? pts[1] = da : pts = [da;pts]
        db=last(d)
        isapprox(db,pts[end]) ? pts[end] = db : pts = [pts;db]
        Fun(x->f[x],pts)
    end
end

function splitmap(g,d::AffineDomain,pts)
    da=first(d)
    isapprox(da,pts[1];atol=sqrt(eps(length(d)))) ? pts[1] = da : pts = [da;pts]
    db=last(d)
    isapprox(db,pts[end];atol=sqrt(eps(length(d)))) ? pts[end] = db : pts = [pts;db]
    Fun(g,pts)
end

function splitmap(g,d::IntervalDomain,pts)
    if length(pts)==1 && (isapprox(first(pts),first(d))  ||  isapprox(last(pts),last(d)))
        Fun(g,d)
    elseif length(pts)==2 && isapprox(first(pts),first(d)) && isapprox(last(pts),last(d))
        Fun(g,d)
    else
        error("implement splitmap for "*string(typeof(d)))
    end
end

function Base.abs{S<:RealSpace,T<:Real}(f::Fun{S,T})
    d=domain(f)

    pts=roots(f)

    if isempty(pts)
        sign(first(f))*f
    else
        splitmap(x->abs(f[x]),d,pts)
    end
end

function Base.abs{S,T}(f::Fun{S,T})
    d=domain(f)

    pts=roots(f)

    if isempty(pts)
        # This makes sure Laurent returns real type
        real(Fun(x->abs(f[x]),space(f)))
    else
        splitmap(x->abs(f[x]),d,pts)
    end
end



function Base.sign{S<:RealSpace,T<:Real}(f::Fun{S,T})
    d=domain(f)

    pts=roots(f)

    if isempty(pts)
        sign(first(f))*one(T,f.space)
    else
        @assert isa(d,AffineDomain)
        da=first(d)
        isapprox(da,pts[1];atol=sqrt(eps(length(d)))) ? pts[1] = da : pts = [da,pts]
        db=last(d)
        isapprox(db,pts[end];atol=sqrt(eps(length(d)))) ? pts[end] = db : pts = [pts,db]
        midpts = .5(pts[1:end-1]+pts[2:end])
        Fun([sign(f[midpts])],pts)
    end
end

# division by fun

function ./{S,T,U,V}(c::Fun{S,T},f::Fun{U,V})
    r=roots(f)
    tol=10eps()
    if length(r)==0 || norm(c[r])<tol
        linsolve(Multiplication(f,space(c)),c;tolerance=tol)
    else
        c.*(1./f)
    end
end

function ./{S,T}(c::Number,f::Fun{S,T})
    r=roots(f)
    tol=10eps()
    @assert length(r)==0
    linsolve(Multiplication(f,space(f)),c*ones(space(f));tolerance=tol)
end

function ./(c::Number,f::Fun{Chebyshev})
    fc = Fun(coefficients(f),Interval())
    r = roots(fc)
    x = Fun(identity)

    # if domain f is small then the pts get projected in
    tol = 50eps()/length(domain(f))


    if length(r) == 0
        linsolve(Multiplication(f,space(f)),c;tolerance=tol)
    elseif length(r) == 1 && (isapprox(r[1],1.) || isapprox(r[1],-1.))
        if sign(r[1]) < 0
            g = divide_singularity(-1,fc)  # divide by 1+x
            Fun(coefficients(c./g,Chebyshev),JacobiWeight(-1,0,domain(f)))
        else
            g = divide_singularity(1,fc)  # divide by 1-x
            Fun(coefficients(c./g,Chebyshev),JacobiWeight(0,-1,domain(f)))
        end
    elseif length(r) ==2 && ((isapprox(r[1],-1) && isapprox(r[2],1)) || (isapprox(r[2],-1) && isapprox(r[1],1)))
        g = divide_singularity(fc) # divide by 1-x^2
        # divide out singularities, tolerance needs to be chosen since we don't get
        # spectral convergence
        # TODO: switch to dirichlet basis
        Fun(coefficients(c./g,Chebyshev),JacobiWeight(-1,-1,domain(f)))
    else
        #split at the roots
        c./splitatroots(f)
    end
end

./{S<:PiecewiseSpace}(c::Number,f::Fun{S})=depiece(map(f->c./f,pieces(f)))
function ./{S<:MappedSpace}(c::Number,f::Fun{S})
    g=c./Fun(coefficients(f),space(f).space)
    Fun(coefficients(g),MappedSpace(domain(f),space(g)))
end
function .^{S<:FunctionSpace,D,T}(f::Fun{MappedSpace{S,D,T}},k::Float64)
    g=Fun(coefficients(f),space(f).space).^k
    Fun(coefficients(g),MappedSpace(domain(f),space(g)))
end


#TODO: Unify following
function .^{S<:Chebyshev,D,T}(f::Fun{MappedSpace{S,D,T}},k::Float64)
    sp=space(f)
    # Need to think what to do if this is ever not the case..
    @assert isapprox(domain(sp.space),Interval())
    fc = Fun(f.coefficients,sp.space) #Project to interval

    r = sort(roots(fc))
    @assert length(r) <= 2

    if length(r) == 0
        Fun(Fun(x->fc[x]^k).coefficients,sp)
    elseif length(r) == 1
        @assert isapprox(abs(r[1]),1)

        if isapprox(r[1],1.)
            Fun(coefficients(divide_singularity(+1,fc)^k),MappedSpace(sp.domain,JacobiWeight(0.,k,sp.space)))
        else
            Fun(coefficients(divide_singularity(-1,fc)^k),MappedSpace(sp.domain,JacobiWeight(k,0.,sp.space)))
        end
    else
        @assert isapprox(r[1],-1)
        @assert isapprox(r[2],1)

        Fun(coefficients(divide_singularity(fc)^k),MappedSpace(sp.domain,JacobiWeight(k,k,sp.space)))
    end
end

function .^(f::Fun{Chebyshev},k::Float64)
    # Need to think what to do if this is ever not the case..
    sp = space(f)
    fc = Fun(f.coefficients) #Project to interval

    r = sort(roots(fc))
    @assert length(r) <= 2

    if length(r) == 0
        Fun(Fun(x->fc[x]^k).coefficients,sp)
    elseif length(r) == 1
        @assert isapprox(abs(r[1]),1)

        if isapprox(r[1],1.)
            Fun(coefficients(divide_singularity(+1,fc)^k),JacobiWeight(0.,k,sp))
        else
            Fun(coefficients(divide_singularity(-1,fc)^k),JacobiWeight(k,0.,sp))
        end
    else
        @assert isapprox(r[1],-1)
        @assert isapprox(r[2],1)

        Fun(coefficients(divide_singularity(fc)^k),JacobiWeight(k,k,sp))
    end
end

# Default is just try solving ODE
function .^{S,T}(f::Fun{S,T},β)
    A=Derivative()-β*differentiate(f)/f
    B=Evaluation(first(domain(f)))
    [B,A]\first(f)^β
end

Base.sqrt{S,T}(f::Fun{S,T})=f^0.5
Base.cbrt{S,T}(f::Fun{S,T})=f^(1/3)

## We use \ as the Fun constructor might miss isolated features

## First order functions


Base.log(f::Fun)=cumsum(differentiate(f)/f)+log(first(f))

# project first to [-1,1] to avoid issues with
# complex derivative
function Base.log{US<:Ultraspherical,T<:Real}(f::Fun{US,T})
    if isreal(domain(f))
        cumsum(differentiate(f)/f)+log(first(f))
    else
        # this makes sure differentiate doesn't
        # make the function complex
        g=log(Fun(f.coefficients,US()))
        @assert isa(space(g),US)
        Fun(g.coefficients,space(f))
    end
end


function Base.log{T<:Real}(f::Fun{Fourier,T})
    if isreal(domain(f))
        cumsum(differentiate(f)/f)+log(first(f))
    else
        # this makes sure differentiate doesn't
        # make the function complex
        g=log(Fun(f.coefficients,Fourier()))
        @assert isa(space(g),Fourier)
        Fun(g.coefficients,space(f))
    end
end


for (op,ODE,RHS,growth) in ((:(Base.exp),"D-f'","0",:(real)),
                            (:(Base.asin),"sqrt(1-f^2)*D","f'",:(imag)),
                            (:(Base.acos),"sqrt(1-f^2)*D","-f'",:(imag)),
                            (:(Base.atan),"(1+f^2)*D","f'",:(imag)),
                            (:(Base.asinh),"sqrt(f^2+1)*D","f'",:(real)),
                            (:(Base.acosh),"sqrt(f^2-1)*D","f'",:(real)),
                            (:(Base.atanh),"(1-f^2)*D","f'",:(real)),
                            (:(Base.erfcx),"D-2f*f'","-2f'/sqrt(π)",:(real)),
                            (:(Base.dawson),"D+2f*f'","f'",:(real)))
    L,R = parse(ODE),parse(RHS)
    @eval begin
        function $op{S,T}(f::Fun{S,T})
            g=chop($growth(f),eps(T))
            xmin=g.coefficients==[0.]?first(domain(g)):indmin(g)
            xmax=g.coefficients==[0.]?last(domain(g)):indmax(g)
            opfxmin,opfxmax = $op(f[xmin]),$op(f[xmax])
            opmax = maxabs((opfxmin,opfxmax))
            if abs(opfxmin) == opmax xmax,opfxmax = xmin,opfxmin end
            # we will assume the result should be smooth on the domain
            # even if f is not
            # This supports Line/Rays
            D=Derivative(domain(f))
            B=Evaluation(domainspace(D),xmax)
            #([B,eval($L)]\[opfxmax/opmax,eval($R)/opmax])*opmax
            linsolve([B,eval($L)],Any[opfxmax/opmax,eval($R)/opmax];tolerance=eps(T))*opmax
        end
    end
end



## Second order functions


Base.sin{S<:FunctionSpace{RealBasis},T<:Real}(f::Fun{S,T}) = imag(exp(im*f))
Base.cos{S<:FunctionSpace{RealBasis},T<:Real}(f::Fun{S,T}) = real(exp(im*f))
Base.sin{S<:Ultraspherical,T<:Real}(f::Fun{S,T}) = imag(exp(im*f))
Base.cos{S<:Ultraspherical,T<:Real}(f::Fun{S,T}) = real(exp(im*f))



for (op,ODE,RHS,growth) in ((:(Base.erf),"f'*D^2+(2f*f'^2-f'')*D","0f'^3",:(imag)),
                            (:(Base.erfi),"f'*D^2-(2f*f'^2+f'')*D","0f'^3",:(real)),
                            (:(Base.erfc),"f'*D^2+(2f*f'^2-f'')*D","0f'^3",:(real)),
                            (:(Base.sin),"f'*D^2-f''*D+f'^3","0f'^3",:(imag)),
                            (:(Base.cos),"f'*D^2-f''*D+f'^3","0f'^3",:(imag)),
                            (:(Base.sinh),"f'*D^2-f''*D-f'^3","0f'^3",:(real)),
                            (:(Base.cosh),"f'*D^2-f''*D-f'^3","0f'^3",:(real)),
                            (:(Base.airyai),"f'*D^2-f''*D-f*f'^3","0f'^3",:(imag)),
                            (:(Base.airybi),"f'*D^2-f''*D-f*f'^3","0f'^3",:(imag)),
                            (:(Base.airyaiprime),"f'*D^2-f''*D-f*f'^3","airyai(f)*f'^3",:(imag)),
                            (:(Base.airybiprime),"f'*D^2-f''*D-f*f'^3","airybi(f)*f'^3",:(imag)))
    L,R = parse(ODE),parse(RHS)
    @eval begin
        function $op{S<:Ultraspherical,T}(f::Fun{S,T})
            g=chop($growth(f),eps(T))
            xmin=g.coefficients==[0.]?first(domain(g)):indmin(g)
            xmax=g.coefficients==[0.]?last(domain(g)):indmax(g)
            opfxmin,opfxmax = $op(f[xmin]),$op(f[xmax])
            opmax = maxabs((opfxmin,opfxmax))
            while opmax≤10eps(T) || abs(f[xmin]-f[xmax])≤10eps(T)
                xmin,xmax = rand(domain(f)),rand(domain(f))
                opfxmin,opfxmax = $op(f[xmin]),$op(f[xmax])
                opmax = maxabs((opfxmin,opfxmax))
            end
            D=Derivative(space(f))
            B=[Evaluation(space(f),xmin),Evaluation(space(f),xmax)]
            ([B,eval($L)]\[opfxmin/opmax,opfxmax/opmax,eval($R)/opmax])*opmax
        end
    end
end

## Second order functions with parameter ν

for (op,ODE,RHS,growth) in ((:(Base.hankelh1),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0f'^3",:(imag)),
                            (:(Base.hankelh2),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0f'^3",:(imag)),
                            (:(Base.besselj),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0f'^3",:(imag)),
                            (:(Base.bessely),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0f'^3",:(imag)),
                            (:(Base.besseli),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D-(f^2+ν^2)*f'^3","0f'^3",:(real)),
                            (:(Base.besselk),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D-(f^2+ν^2)*f'^3","0f'^3",:(real)),
                            (:(Base.besselkx),"f^2*f'*D^2+((-2f^2+f)*f'^2-f^2*f'')*D-(f+ν^2)*f'^3","0f'^3",:(real)),
                            (:(Base.hankelh1x),"f^2*f'*D^2+((2im*f^2+f)*f'^2-f^2*f'')*D+(im*f-ν^2)*f'^3","0f'^3",:(imag)),
                            (:(Base.hankelh2x),"f^2*f'*D^2+((-2im*f^2+f)*f'^2-f^2*f'')*D+(-im*f-ν^2)*f'^3","0f'^3",:(imag)))
    L,R = parse(ODE),parse(RHS)
    @eval begin
        function $op{S<:Ultraspherical,T}(ν,f::Fun{S,T})
            g=chop($growth(f),eps(T))
            xmin=g.coefficients==[0.]?first(domain(g)):indmin(g)
            xmax=g.coefficients==[0.]?last(domain(g)):indmax(g)
            opfxmin,opfxmax = $op(ν,f[xmin]),$op(ν,f[xmax])
            opmax = maxabs((opfxmin,opfxmax))
            while opmax≤10eps(T) || abs(f[xmin]-f[xmax])≤10eps(T)
                xmin,xmax = rand(domain(f)),rand(domain(f))
                opfxmin,opfxmax = $op(ν,f[xmin]),$op(ν,f[xmax])
                opmax = maxabs((opfxmin,opfxmax))
            end
            D=Derivative(space(f))
            B=[Evaluation(space(f),xmin),Evaluation(space(f),xmax)]
            ([B,eval($L)]\[opfxmin/opmax,opfxmax/opmax,eval($R)/opmax])*opmax
        end
    end
end

Base.exp2(f::Fun) = exp(log(2)*f)
Base.exp10(f::Fun) = exp(log(10)*f)
Base.log2(f::Fun) = log(f)/log(2)
Base.log10(f::Fun) = log(f)/log(10)

##TODO: the spacepromotion doesn't work for tan/tanh for a domain including zeros of cos/cosh inside.
Base.tan(f::Fun) = sin(f)/cos(f) #This is inaccurate, but allows space promotion via division.
Base.tanh(f::Fun) = sinh(f)/cosh(f) #This is inaccurate, but allows space promotion via division.

for (op,oprecip,opinv,opinvrecip) in ((:(Base.sin),:(Base.csc),:(Base.asin),:(Base.acsc)),
                                      (:(Base.cos),:(Base.sec),:(Base.acos),:(Base.asec)),
                                      (:(Base.tan),:(Base.cot),:(Base.atan),:(Base.acot)),
                                      (:(Base.sinh),:(Base.csch),:(Base.asinh),:(Base.acsch)),
                                      (:(Base.cosh),:(Base.sech),:(Base.acosh),:(Base.asech)),
                                      (:(Base.tanh),:(Base.coth),:(Base.atanh),:(Base.acoth)))
    @eval begin
        $oprecip(f::Fun) = 1/$op(f)
        $opinvrecip(f::Fun) = $opinv(1/f)
    end
end

rad2deg(f::Fun) = 180*f/π
deg2rad(f::Fun) = π*f/180

for (op,opd,opinv,opinvd) in ((:(Base.sin),:(Base.sind),:(Base.asin),:(Base.asind)),
                              (:(Base.cos),:(Base.cosd),:(Base.acos),:(Base.acosd)),
                              (:(Base.tan),:(Base.tand),:(Base.atan),:(Base.atand)),
                              (:(Base.sec),:(Base.secd),:(Base.asec),:(Base.asecd)),
                              (:(Base.csc),:(Base.cscd),:(Base.acsc),:(Base.acscd)),
                              (:(Base.cot),:(Base.cotd),:(Base.acot),:(Base.acotd)))
    @eval begin
        $opd(f::Fun) = $op(deg2rad(f))
        $opinvd(f::Fun) = rad2deg($opinv(f))
    end
end

#Won't get the zeros exactly 0 anyway so at least this way the length is smaller.
Base.sinpi(f::Fun) = sin(π*f)
Base.cospi(f::Fun) = cos(π*f)

function Base.airy(k::Number,f::Fun)
    if k == 0
        airyai(f)
    elseif k == 1
        airyaiprime(f)
    elseif k == 2
        airybi(f)
    elseif k == 3
        airybiprime(f)
    else
        error("invalid argument")
    end
end

Base.besselh(ν,k::Integer,f::Fun) = k == 1 ? hankelh1(ν,f) : k == 2 ? hankelh2(ν,f) : throw(Base.Math.AmosException(1))

for jy in ("j","y"), ν in (0,1)
    bjy = symbol(string("bessel",jy))
    bjynu = parse(string("Base.bessel",jy,ν))
    @eval begin
        $bjynu(f::Fun) = $bjy($ν,f)
    end
end

## Miscellaneous
for op in (:(Base.expm1),:(Base.log1p),:(Base.lfact),:(Base.sinc),:(Base.cosc),
           :(Base.erfinv),:(Base.erfcinv),:(Base.beta),:(Base.lbeta),
           :(Base.eta),:(Base.zeta),:(Base.gamma),:(Base.lgamma),
           :(Base.polygamma),:(Base.invdigamma),:(Base.digamma),:(Base.trigamma))
    @eval begin
        $op{S,T}(f::Fun{S,T})=Fun(x->$op(f[x]),domain(f))
    end
end
