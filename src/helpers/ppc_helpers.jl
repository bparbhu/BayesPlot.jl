using DataFrames, DataFramesMeta
using Optim
using Interpolations
using StatsBase
using Distributions


function validate_group(group, n_obs)
    # sanity checks
    @assert (isa(group, AbstractVector) || isa(group, CategoricalArray)) && (length(n_obs) == 1) && (n_obs == trunc(Int, n_obs))

    if !isa(group, CategoricalArray)
        group = categorical(group)
    end

    if any(ismissing, group)
        throw("NAs not allowed in 'group'.")
    end

    if length(group) != n_obs
        throw("length(group) must be equal to the number of observations.")
    end

    return group
end



function is_vector_or_1Darray(x)
    return isa(x, Vector) && !isa(x, Dict)
end


function is_whole_number(x, tol = eps(Float64))
    if !isa(x, Number)
        return false
    else
        return abs(x - round(x)) < tol
    end
end


function all_whole_number(x; kwargs...)
    return all(is_whole_number.(x; kwargs...))
end

function all_counts(x; kwargs...)
    return all_whole_number(x; kwargs...) && minimum(x) >= 0
end

function validate_y(y)
    @assert isa(y, AbstractVector{<:Number}) "'y' must be a vector of numbers."

    if any(isnan.(y))
        throw(ArgumentError("NAs not allowed in 'y'."))
    end

    return y
end


function validate_predictions(predictions, n_obs = nothing)
    @assert isa(predictions, AbstractMatrix{<:Number}) "predictions must be a matrix of numbers."
    
    if n_obs !== nothing
        @assert length(n_obs) == 1 && n_obs == convert(Int, n_obs) "n_obs should be a single integer."
    end

    if any(isnan.(predictions))
        throw(ArgumentError("NAs not allowed in predictions."))
    end

    if n_obs !== nothing && (size(predictions, 2) != n_obs)
        throw(ArgumentError("number of columns in 'yrep' must be equal to length(y)."))
    end

    # get rid of names but keep them as an attribute in case we want them
    obs_names = nothing
    return predictions
end


function validate_pit(pit)
    if any(isnan.(pit))
        throw(ArgumentError("NAs not allowed in 'pit'."))
    end

    @assert isa(pit, AbstractVector{<:Number}) "'pit' must be a vector of numbers."

    if any(pit .> 1) || any(pit .< 0)
        throw(ArgumentError("'pit' must only contain values between 0 and 1."))
    end

    return pit
end


function validate_x(x = nothing, y; unique_x = false)
    if x === nothing
        x = 1:length(y)
    end

    @assert isa(x, AbstractVector{<:Number}) "'x' must be a vector of numbers."

    if !is_vector_or_1Darray(x)
        throw(ArgumentError("'x' must be a vector or 1D array."))
    end

    if length(x) != length(y)
        throw(ArgumentError("length(x) must be equal to length(y)."))
    end

    if any(isnan.(x))
        throw(ArgumentError("NAs not allowed in 'x'."))
    end

    if unique_x
        @assert length(x) == length(unique(x)) "x must contain unique elements."
    end

    return x
end


function melt_predictions(predictions)
    obs_names = propertynames(predictions)

    molten_preds = @pipe predictions |>
                   stack(_, Not(:rep_id)) |>
                   rename(_, :variable => :y_id, :value => :value) |>
                   transform(_, :y_id => (y_id -> indexin(y_id, obs_names)) => :y_id, :rep_id => :rep_id) |>
                   transform(_, :y_id => ByRow(getindex.(obs_names, Ref(:y_id))) => :y_name, :rep_id => :rep_label)

    return molten_preds
end


function melt_and_stack(y, yrep)
    y_text = "y"
    yrep_text = "yrep"
    
    molten_preds = DataFrame(value = vec(yrep), y_id = repeat(1:length(y), size(yrep, 1)), rep_id = repeat(1:size(yrep, 1), inner = length(y)))
    molten_preds[!, :rep_label] = "rep_" .* string.(molten_preds[!, :rep_id])
    molten_preds[!, :y_name] = "y_" .* string.(molten_preds[!, :y_id])

    ydat = DataFrame(
        rep_label = fill(y_text, length(y)),
        rep_id = fill(NA, length(y)),
        y_id = 1:length(y),
        y_name = "y_" .* string.(1:length(y)),
        value = y
    )
    
    data = vcat(molten_preds, ydat)
    data[!, :is_y] = ismissing.(data[!, :rep_id])
    data[!, :is_y_label] = ifelse.(data[!, :is_y], y_text, yrep_text)

    return data
end


function p_interior(p_int, x1, x2, z1, z2, N)
    # Ratio between the length of the evaluation interval and the total length of
    # the interval left to cover by ECDF.
    z_tilde = (z2 - z1) / (1 - z1)
    
    # Number of samples left to cover by ECDF.
    N_tilde = repeat(N .- x1, outer=(length(x2)))
    
    p_int = repeat(p_int, outer=(length(x2)))
    
    x_diff = x2 .- reshape(x1, 1, length(x1))
    
    # Probability of each transition from a value in x1 to a value in x2.
    p_x2_int = p_int .* pdf.(Binomial.(N_tilde, z_tilde), x_diff)
    
    return sum(p_x2_int, dims=2)[:]
end



function adjust_gamma_optimize(N, K, prob)
    target(gamma) = begin
        z = 1:(K - 1) / K
        z1 = vcat(0, z)
        z2 = vcat(z, 1)
        
        x2_lower = qbinom.(gamma / 2, N, z2)
        x2_upper = vcat(N .- reverse(x2_lower)[2:end], 1)
        
        x1 = 0
        p_int = 1
        for i in eachindex(z1)
            p_int = p_interior(p_int, x1, x2_lower[i]:x2_upper[i], z1[i], z2[i], N)
            x1 = x2_lower[i]:x2_upper[i]
        end
        return abs(prob - sum(p_int))
    end
    
    res = optimize(target, 0, 1 - prob)
    return Optim.minimizer(res)
end


function adjust_gamma(N, L=1, K=N, prob=0.99, M=1000, interpolate_adj=nothing)
    if !all(isinteger.([K, N, L])) || any([K, N, L] .<= 0)
        error("Parameters 'N', 'L', and 'K' must be positive integers.")
    end
    if prob >= 1 || prob <= 0
        error("Value of 'prob' must be in (0,1).")
    end
    if isnothing(interpolate_adj)
        if K <= 200
            interpolate_adj = false
        else
            interpolate_adj = true
        end
    end
    if interpolate_adj
        gamma = interpolate_gamma(N=N, K=K, prob=prob, L=L)
    elseif L == 1
        gamma = adjust_gamma_optimize(N=N, K=K, prob=prob)
    else
        gamma = adjust_gamma_simulate(N=N, L=L, K=K, prob=prob, M=M)
    end
    return gamma
end


function get_interpolation_values(N, K, L, prob, gamma_adj)
    for dim in ["L", "prob"]
        if !(get(dim) in gamma_adj[dim])
            error("No precomputed values to interpolate from for $dim = $(get(dim)). \n" *
                  "Values of $dim available for interpolation: $(join(unique(gamma_adj[dim]), ", ")).")
        end
    end
    vals = gamma_adj[gamma_adj.L .== L .& gamma_adj.prob .== prob, :]

    if N > maximum(vals.N)
        error("No precomputed values to interpolate from for sample length of $N. \n" *
              "Please use a subsample of length $(maximum(vals.N)) or smaller, or consider setting 'interpolate_adj' = FALSE.")
    end
    if N < minimum(vals.N)
        error("No precomputed values to interpolate from for sample length of $N. \n" *
              "Please use a subsample of length $(minimum(vals.N)) or larger, or consider setting 'interpolate_adj' = FALSE.")
    end
    if K > maximum(vals[vals.N .<= N, :].K)
        error("No precomputed values available for interpolation for 'K' = $K. \n" *
              "Try either setting a value of 'K' <= $(maximum(vals[vals.N .<= N, :].K)) or 'interpolate_adj' = FALSE.")
    end
    if K < minimum(vals[vals.N .<= N, :].K)
        error("No precomputed values available for interpolation for 'K' = $K. \n" *
              "Try either setting a value of 'K' >= $(minimum(vals[vals.N .<= N, :].K)) or 'interpolate_adj' = FALSE.")
    end
    return vals
end


function interpolate_gamma(N, K, prob, L, gamma_adj)
    # Find the precomputed values useful for the interpolation task
    vals = get_interpolation_values(N, K, L, prob, gamma_adj)
    
    # Largest lower bound and smallest upper bound for N among precomputed values
    N_lb = maximum(vals[vals.N .<= N, :N])
    N_ub = minimum(vals[vals.N .>= N, :N])
    
    # Approximate largest lower bound and smallest upper bound for gamma
    log_gamma_lb = interp1(log.(vals[vals.N .== N_lb, :K]), log.(vals[vals.N .== N_lb, :val]), log(K))
    log_gamma_ub = interp1(log.(vals[vals.N .== N_ub, :K]), log.(vals[vals.N .== N_ub, :val]), log(K))
    
    if N_ub == N_lb
        log_gamma_approx = log_gamma_lb
    else
        # Approximate log_gamma for the desired value of N
        log_gamma_approx = interp1(log.([N_lb, N_ub]), [log_gamma_lb, log_gamma_ub], log(N))
    end
    return exp(log_gamma_approx)
end


function interp1(x, y, xout)
    itp = LinearInterpolation(x, y, extrapolation_bc=Flat())
    return itp(xout)
end


function alpha_quantile(gamma, alpha, tol = 0.001)
    a = quantile(gamma, alpha)
    a_tol = quantile(gamma, alpha + tol)
    
    if a == a_tol
        if minimum(gamma) < a
            # take the largest value that doesn't exceed the tolerance.
            a = maximum(gamma[gamma .< a])
        end
    end
    
    return a
end

function ecdf_intervals(gamma, N, K, L = 1)
    lims = Dict()
    z = range(0, 1, length = K + 1)
    
    if L == 1
        lims["lower"] = quantile.(Binomial.(N, z), gamma / 2)
        lims["upper"] = quantile.(Binomial.(N, z), 1 - gamma / 2)
    else
        n = N * (L - 1)
        k = floor.(z * L * N)
        lims["lower"] = quantile.(Hypergeometric.(N, n, k), gamma / 2)
        lims["upper"] = quantile.(Hypergeometric.(N, n, k), 1 - gamma / 2)
    end
    
    return lims
end

function u_scale(x)
    return rank(x) ./ length(x)
end

function create_rep_ids(ids)
    return "italic(y)[rep] ($(ids))"
end


y_label() = "italic(y)"
yrep_label() = "italic(y)[rep]"
ypred_label() = "italic(y)[pred]"

