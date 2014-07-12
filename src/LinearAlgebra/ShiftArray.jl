

type ShiftArray{T<:Number}
  data::Array{T,2}
  rowindex::Int    
  colindex::Int
end

ShiftArray(dat::Array,ind::Integer)=ShiftArray(dat,0,ind)
ShiftArray(T::DataType,ind::Integer)=ShiftArray(Array(T,0,0),0,ind)
ShiftArray(ind::Integer)=ShiftArray(Float64,ind)

sazeros(T::DataType,n::Range1,m::Range1)=ShiftArray(zeros(T,length(n),length(m)),1-n[1],1-m[1])
sazeros(n::Range1,m::Range1)=sazeros(Float64,n,m)





Base.setindex!(S::ShiftArray,x::Number,k::Integer,j::Integer)=(S.data[k + S.rowindex, j + S.colindex] = x)

Base.getindex(S::ShiftArray,k,j) = S.data[k + S.rowindex, j + S.colindex]


Base.size(S::ShiftArray,k)=size(S.data,k)

columninds(A::ShiftArray)=1-A.colindex,size(A,2)-A.colindex
rowinds(A::ShiftArray)=1-A.rowindex,size(A,1)-A.rowindex

columnrange(A::ShiftArray)=Range1(columninds(A)...)
rowrange(A::ShiftArray)=Range1(rowinds(A)...)

*(S::ShiftArray,x::Number)=ShiftArray(x*S.data,S.rowindex,S.colindex)
*(x::Number,S::ShiftArray)=ShiftArray(x*S.data,S.rowindex,S.colindex)
.*(S::ShiftArray,x::Number)=ShiftArray(x*S.data,S.rowindex,S.colindex)
.*(x::Number,S::ShiftArray)=ShiftArray(x*S.data,S.rowindex,S.colindex)



function shiftarray_const_addentries!(B::ShiftArray,c::Number,A::ShiftArray,kr::Range1)    
    for k=kr,j=columnrange(B)
        A[k,j] += c*B[k,j]
    end
    
    A
end



function +{T<:Number}(A::ShiftArray{T},B::ShiftArray{T})
    @assert size(A,1) == size(B,1)
    @assert A.rowindex == B.rowindex
    
    cmin=min(columninds(A)[1],columninds(B)[1])
    cmax=max(columninds(A)[end],columninds(B)[end])    
    cind=1-cmin
    
    ret=zeros(T,size(A,1),cmax-cmin+1)
    
    ret[:,columnrange(A)+cind]=A.data
    ret[:,columnrange(B)+cind]+=B.data
    
    ShiftArray(ret,A.rowindex,cind)
end

function -{T<:Number}(A::ShiftArray{T},B::ShiftArray{T})
    @assert size(A,1) == size(B,1)
    @assert A.rowindex == B.rowindex
    
    cmin=min(columninds(A)[1],columninds(B)[1])
    cmax=max(columninds(A)[end],columninds(B)[end])    
    cind=1-cmin
    
    ret=zeros(T,size(A,1),cmax-cmin+1)
    
    ret[:,columnrange(A)+cind]=A.data
    ret[:,columnrange(B)+cind]-=B.data
    
    ShiftArray(ret,A.rowindex,cind)
end


function Base.resize!{T<:Number}(S::ShiftArray{T},n::Integer,m::Integer)
    olddata = S.data
    S.data = zeros(T,n,m)
    
    if size(olddata,1) != 0
        S.data[1:size(olddata,1),1:m] = olddata[:,1:m]
    end
    
    S
end






