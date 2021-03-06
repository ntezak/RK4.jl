module RK4
export rk4solve, rk4solve_stochastic

    
macro addto!(v1, v2, factor)
    # my own little devectorization macro. not sure if necessary.
    quote
        local jj::Int
        for jj=1:length($(esc(v1)))
            $(esc(v1))[jj] += $(esc(factor)) * $(esc(v2))[jj]
        end
    end
end
    
    
    
function rk4solve{T}(ode!::Function, z0::AbstractVector{T}, tlist::AbstractVector{Float64}, hmax::Float64, odeparams=nothing; verbose=true)
    @assert length(tlist) >= 1
    n = length(z0)
    t::Float64 = Float64(tlist[1])
    retvals = zeros(T, n, length(tlist))
    z = copy(z0)
    k1 = zeros(T, n)
    k2 = zeros(T, n)
    k3 = zeros(T, n)
    k4 = zeros(T, n)
    retvals[:,1] = z


    jjj = 1
    perc_interval = (tlist[end]-tlist[1])/100.

    if verbose
        print("[")
    end

    for kk=2:length(tlist)
        while(t < tlist[kk])
            
            # within this loop, use retvals[:,kk] 
            # as extra temporary variable
            retvals[:,kk] = z
            
            h = min(tlist[kk]-t, hmax)
            ode!(t, z, k1, odeparams)

            t += .5 .* h
            z[:] += .5 * h * k1
            ode!(t, z, k2, odeparams)
            
            z[:] = retvals[:,kk]
            z[:] += .5 * h * k2
            ode!(t, z, k3, odeparams)
        
            t+= .5 * h
            z[:] = retvals[:,kk]
            z[:] += h * k3
            ode!(t, z, k4, odeparams)
            
            for jj=1:n
                z[jj] = (retvals[jj,kk] + h/6. * (k1[jj] + 2.*(k2[jj] + k3[jj]) + k4[jj]))
            end
            
            if h < hmax
                break
            end




        end
        retvals[:,kk] = z
        t = tlist[kk]

        if verbose
            while t / perc_interval > jjj
                print(".")
                if jjj % 10 ==0
                    print("|")
                end
                jjj += 1
            end
        end

    end
    if verbose
        println("]")
    end
    retvals
end

function rk4solve_stochastic{T}(sde!::Function, z0::AbstractVector{T}, tlist::AbstractVector{Float64}, hmax::Float64, n_noises::Int, sdeparams=nothing; verbose=true, seed=0)
    @assert length(tlist) >= 1
    n = length(z0)
    
    t::Float64 = Float64(tlist[1])
    retvals = zeros(T, n, length(tlist))
    kk::Int = 0
    jj::Int = 0
    h::Float64 = 0.
    z = copy(z0)
    k1 = zeros(T, n)
    k2 = zeros(T, n)
    k3 = zeros(T, n)
    k4 = zeros(T, n)

    
    rng = MersenneTwister(seed)
    
    w = zeros(Float64, n_noises)
    retws = zeros(Float64, n_noises, length(tlist)-1)
    
    jjj = 1
    perc_interval = (tlist[end]-tlist[1])/100.


    if verbose
        print("[")
    end


    retvals[:,1] = z
    for kk=2:length(tlist)
        while(t < tlist[kk])
            
            randn!(rng, w)
            
            retvals[:,kk] = z
            
            h = min(tlist[kk]-t, hmax)
            w /= sqrt(h)
            
            sde!(t, z, w, k1, sdeparams)

            t += .5 * h
            z[:] += .5 * h * k1
            sde!(t, z, w, k2, sdeparams)
            z[:] = retvals[:,kk]
            z[:] += .5 * h * k2
            sde!(t, z, w, k3, sdeparams)
        
            t+= .5 * h
            z[:] = retvals[:,kk]
            z[:] += h * k3
            sde!(t, z, w, k4, sdeparams)
            
            for jj=1:n
                z[jj] = (retvals[jj,kk] + h/6. * (k1[jj] + 2.*(k2[jj] + k3[jj]) + k4[jj]))
            end
            retws[:,kk-1] += w * h

            if h < hmax
                break
            end
			
        end
		retws[:,kk-1] /= tlist[kk]-tlist[kk-1]
        retvals[:,kk] = z
        t = tlist[kk]

        if verbose
            while t / perc_interval > jjj
                print(".")
                if jjj % 10 ==0
                    print("|")
                end
                jjj += 1
            end
        end

    end
    if verbose
        println("]")
    end

    retvals, retws
end
end #module                        