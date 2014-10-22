if isdir(Pkg.dir("FastGaussQuadrature"))
    require("FastGaussQuadrature")
    
    gaussjacobi(n,a,b)=Main.FastGaussQuadrature.gaussjacobi(n,a,b)
    gausschebyshev(n,knd)=Main.FastGaussQuadrature.gausschebyshev(n,knd)
else
    for op in (:gaussjacobi,:gausschebyshev)
        @eval $op(n...)=error("Currently require FastGaussQuadrature.jl")    
    end
end

points(S::JacobiSpace,n)=fromcanonical(S,gaussjacobi(n,S.a,S.b)[1])
function transform(S::JacobiSpace,v::Vector,xw::(Vector,Vector))
    x,w=xw
    V=jacobip(0:length(v)-1,S.a,S.b,x)'
    nrm=(V.^2)*w
    
    V*(w.*v)./nrm
end

transform(S::JacobiSpace,v::Vector)=transform(S,v,gaussjacobi(length(v),S.a,S.b))

itransform(S::JacobiSpace,cfs::Vector,x::Vector)=jacobip(0:length(cfs)-1,S.a,S.b,tocanonical(S,x))*cfs
itransform(S::JacobiSpace,cfs::Vector)=itransform(S,cfs,points(S,length(cfs)))


evaluate(f::Fun{JacobiSpace},x::Number)=dot(jacobip(0:length(f)-1,f.space.a,f.space.b,tocanonical(f,x)),f.coefficients)
evaluate(f::Fun{JacobiSpace},x::Vector)=jacobip(0:length(f)-1,f.space.a,f.space.b,tocanonical(f,x))*f.coefficients


## JacobiWeightSpace


function plan_transform(S::JacobiWeightSpace{JacobiSpace},n::Integer)
    m=S.β
    @assert isapproxinteger(m)
    
    if S.α==S.space.b==0 && S.space.a==2m+1
        gaussjacobi(n,1.,0.)
    elseif S.α==0 && S.space.b ==-0.5 && S.space.a==2m+0.5
        gausschebyshev(n,4) # a=0.5,b==-0.5
    elseif S.α==0 && S.space.b ==-0.5 && S.space.a==2m-0.5
        gausschebyshev(n) # a=-0.5,b==-0.5
    end
end

points(S::JacobiWeightSpace{JacobiSpace},n)=fromcanonical(S,plan_transform(S,n)[1])


transform(S::JacobiWeightSpace{JacobiSpace},vals::Vector)=transform(S,vals,plan_transform(S,length(vals)))
function transform(S::JacobiWeightSpace{JacobiSpace},vals::Vector,xw::(Vector,Vector))
    # JacobiSpace and JacobiWeightSpace have different a/b orders

    m=S.β
    @assert isapproxinteger(m)
    @assert S.α==0 && (S.space.b==0 && S.space.a==2m+1) || (S.space.b ==-0.5 && S.space.a==2m+0.5)
    
    n=length(vals)
    x,w=xw
    if m==0
        V=jacobip(0:n-1,S.space,x)'
        nrm=(V.^2)*w
        (V*(w.*vals))./nrm
    elseif n>m
        w2=(1-x).^m
        mw=w2.*w
        
        V=jacobip(0:n-int(m)-1,S.space,x)'   
          # only first m coefficients are accurate
          # since Gauss quad is accurate up to polys of degree 2n-1
          # we get one more coefficient because we normalize, so the
          # error for poly of degree 2n is annihilated
        
        
        nrm=(V.^2)*(w2.*mw)
        
        (V*(mw.*vals))./nrm
    else
        [0.]
    end

end


