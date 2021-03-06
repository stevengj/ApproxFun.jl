## Plotting

export domainplot


## Vector routines

function gadflyopts(;axis=-1,title=-1)
    require("Gadfly")

    opts=Any[Main.Gadfly.Geom.path]

    if axis != -1
        if length(axis)==2
            opts=[opts;Main.Gadfly.Scale.y_continuous(minvalue=axis[1],maxvalue=axis[2])]
        elseif length(axis)==4
            opts=[opts;Main.Gadfly.Scale.x_continuous(minvalue=axis[1],maxvalue=axis[2]);
                    Main.Gadfly.Scale.y_continuous(minvalue=axis[3],maxvalue=axis[4])]
        end
    end


    if title != -1
        opts=[opts;Main.Gadfly.Guide.title(string(title))]
    end
    opts
end

gadflyopts(opts...)=gadflyopts(;opts...)

function gadflyplot{T<:Real}(xx::Vector{T},yy::Vector;opts...)
    require("Gadfly")
    Main.Gadfly.plot(x=xx, y=yy,gadflyopts(opts...)...)
end

gadflylayer{T<:Real}(xx::Vector{T},yy::Vector)=Main.Gadfly.layer(x=xx, y=yy, Main.Gadfly.Geom.path)


function gadflyplot{T<:Complex}(xx::Vector{T},yy::Vector;opts...)
    warn("Complex domain, projecting to real axis")
    gadflyplot(real(xx),yy;opts...)
end

function gadflyplot{T<:Real}(x::Vector{T},y::Vector{Complex{Float64}};opts...)
    require("Gadfly")
    require("DataFrames")
    r=real(y)
    i=imag(y)

    dat=Main.DataFrames.DataFrame(Any[[x,x],[r,i],[fill("Re",length(x)),fill("Im",length(x))]],Main.DataFrames.Index((@compat Dict(:x=>1,:y=>2,:Function=>3)),
            [:x,:y,:Function]))

    Main.Gadfly.plot(dat,x="x",y="y",color="Function",gadflyopts(opts...)...)
end

#Plot multiple contours
function gadflyplot{T<:Real,V<:Real}(x::Matrix{T},y::Matrix{V};opts...)
    require("Gadfly")
    require("DataFrames")

    dat=Main.DataFrames.DataFrame(Any[vec(x),vec(y),[[fill(string(k),size(x,1)) for k=1:size(y,2)]...]],Main.DataFrames.Index((@compat Dict(:x=>1,:y=>2,:Function=>3)),
            [:x,:y,:Function]))

    Main.Gadfly.plot(dat,x="x",y="y",color="Function",gadflyopts(opts...)...)
end




function gadflycontour(x::Vector,y::Vector,z::Matrix;levels=-1,axis=-1)
    require("Gadfly")
    if axis==-1
        axis=[x[1],x[end],y[1],y[end]]
    end

    if levels==-1
        Main.Gadfly.plot(x=x,y=y,z=z,Main.Gadfly.Geom.contour,
                    Main.Gadfly.Scale.x_continuous(minvalue=axis[1],maxvalue=axis[2]),
                    Main.Gadfly.Scale.y_continuous(minvalue=axis[3],maxvalue=axis[4]))
    else
        Main.Gadfly.plot(x=x,y=y,z=z,
                            Main.Gadfly.Geom.contour(levels=levels),
                            Main.Gadfly.Scale.x_continuous(minvalue=axis[1],maxvalue=axis[2]),
                            Main.Gadfly.Scale.y_continuous(minvalue=axis[3],maxvalue=axis[4]))
    end
end

function gadflycontourlayer(x::Vector,y::Vector,z::Matrix;levels=-1)
    require("Gadfly")


    if levels==-1
        Main.Gadfly.layer(x=x,y=y,z=z,Main.Gadfly.Geom.contour)
    else
        Main.Gadfly.layer(x=x,y=y,z=z,Main.Gadfly.Geom.contour(levels=levels))
    end
end

function dotplot{T<:Real,V<:Real}(x::Vector{T},y::Vector{V};axis=-1)
    require("Gadfly")
    if axis==-1
        Main.Gadfly.plot(x=x,y=y)
    else
        Main.Gadfly.plot(x=x,y=y,Main.Gadfly.Scale.y_continuous(minvalue=axis[1],maxvalue=axis[2]))
    end
end
dotplot{T<:Number}(x::Vector{T})=dotplot(real(x),imag(x))
dotlayer{T<:Real,V<:Real}(x::Vector{T},y::Vector{V})=Main.Gadfly.layer(x=x,y=y,Main.Gadfly.Geom.point)
dotlayer{T<:Number}(x::Vector{T})=dotlayer(real(x),imag(x))


function gadflyplot(opts...;kwds...)
    require("Gadfly")
    Main.Gadfly.plot(opts...;kwds...)
end

## Functional

gadflyplot{S}(B::Evaluation{S,Float64})=Main.Gadfly.plot(x=ones(6)*B.x,y=[0.:5.],Main.Gadfly.Geom.line)
gadflyplot{S}(B::Evaluation{S,Bool})=Main.Gadfly.plot(x=ones(6)*(B.x?first(domain(B)):last(domain(B))),y=[0.:5.],Main.Gadfly.Geom.line)
gadflyplot{T<:Real,E<:Evaluation}(B::ConstantTimesFunctional{T,E})=gadflyplot(B.op)


