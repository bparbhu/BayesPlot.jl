using Gadfly
using DataFrames
using MeltArrays
using LaTeXStrings

include("ppc_helpers.jl")


function ppc_error_hist(y::Vector, yrep::Matrix; facet_args = Dict(), binwidth = nothing, breaks = nothing, freq = true)
    df = ppc_error_data(y, yrep)
    p = Gadfly.plot(df,
        x = :error,
        Geom.histogram(binwidth = binwidth, breaks = breaks),
        Guide.title("PPC Error Histogram"),
        Guide.xlabel("Error (y - yrep)"),
        Guide.ylabel("Frequency"))
    return p
end

function ppc_error_hist_grouped(y::Vector, yrep::Matrix, group::Vector; facet_args = Dict(), binwidth = nothing, breaks = nothing, freq = true)
    df = ppc_error_data(y, yrep, group)
    p = Gadfly.plot(df,
        x = :error,
        color = :group,
        Geom.histogram(binwidth = binwidth, breaks = breaks),
        Guide.title("PPC Error Histogram (Grouped)"),
        Guide.xlabel("Error (y - yrep)"),
        Guide.ylabel("Frequency"))
    return p
end

function ppc_error_scatter(y::Vector, yrep::Matrix; facet_args = Dict(), size = 2.5, alpha = 0.8)
    df = ppc_error_data(y, yrep)
    p = Gadfly.plot(df,
        x = :y,
        y = :error,
        Geom.point(size = size, alpha = alpha),
        Guide.title("PPC Error Scatter"),
        Guide.xlabel("Y"),
        Guide.ylabel("Error (y - yrep)"))
    return p
end

function ppc_error_scatter_avg(y::Vector, yrep::Matrix; size = 2.5, alpha = 0.8)
    df = ppc_error_data(y, yrep)
    avg_error = by(df, :y, avg_error = :error => mean)
    p = Gadfly.plot(avg_error,
        x = :y,
        y = :avg_error,
        Geom.point(size = size, alpha = alpha),
        Guide.title("PPC Error Scatter (Average)"),
        Guide.xlabel("Y"),
        Guide.ylabel("Average Error (y - yrep)"))
    return p
end

function ppc_error_scatter_avg_grouped(y::Vector, yrep::Matrix, group::Vector; facet_args = Dict(), size = 2.5, alpha = 0.8)
    df = ppc_error_data(y, yrep, group)
    avg_error = by(df, [:y, :group], avg_error = :error => mean)
    p = Gadfly.plot(avg_error,
        x = :y,
        y = :avg_error,
        color = :group,
        Geom.point(size = size, alpha = alpha),
        Guide.title("PPC Error Scatter (Average, Grouped)"),
        Guide.xlabel("Y"),
        Guide.ylabel("Average Error (y - yrep)"))
    return p
end

function ppc_error_scatter_avg_vs_x(y::Vector, yrep::Matrix, x::Vector; size = 2.5, alpha = 0.8)
    df = ppc_error_data(y, yrep)
    df.x = repeat(x, outer = size(yrep, 2))
    avg_error = by(df, :x, avg_error = :error => mean)
    p = Gadfly.plot(avg_error,
        x = :x,
        y = :avg_error,
        Geom.point(size = size, alpha = alpha),
        Guide.title("PPC Error Scatter (Average vs X)"),
        Guide.xlabel("X"),
        Guide.ylabel("Average Error (y - yrep)"))
    return p
end

function ppc_error_binned(y::Vector, yrep::Matrix; facet_args = Dict(), bins = nothing, size = 1, alpha = 0.25)
    df = ppc_error_data(y, yrep)
    df.binned_y = cut(df.y, bins)
    binned_error = by(df, :binned_y, avg_error = :error => mean)
    p = Gadfly.plot(binned_error,
        x = :binned_y,
        y = :avg_error,
        Geom.bar(width = size, alpha = alpha),
        Guide.title("PPC Error Binned"),
        Guide.xlabel("Binned Y"),
        Guide.ylabel("Average Error (y - yrep)"))
    return p
end


function ppc_error_data(y, yrep, group = nothing)
    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))
    
    if !isnothing(group)
        group = validate_group(group, length(y))
    end
    
    errors = compute_errors(y, yrep) |> melt_predictions
    
    errors = hcat(DataFrame(y_obs = y[errors.y_id]), errors)
    
    if !isnothing(group)
        errors = hcat(DataFrame(group = group[errors.y_id]), errors)
    end
    
    return errors
end


function predictive_error(object::AbstractMatrix, y, args...)
    if !isa(object, Matrix)
        throw(ArgumentError("For the default method 'object' should be a matrix."))
    end
    return _pred_errors(object, y)
end

function _pred_errors(object::AbstractMatrix, y)
    @assert isa(object, Matrix) && length(y) == size(object, 2)
    return -1 .* object .+ y'
end


function compute_errors(y, yrep)
    return predictive_error(object = yrep, y = y)
end


function error_hist_facets(facet_args;
                           grouped::Bool = false,
                           ignore::Bool = false,
                           scales_default::String = "fixed")
    if ignore
        return Geom.nullgeom
    end

    if grouped
        facet_fun = "facet_grid"
        facet_args["facets"] = @formula(rep_id ~ group)
    else
        facet_fun = "facet_wrap"
        facet_args["facets"] = @formula(rep_id)
    end
    facet_args["scales"] = get(facet_args, "scales", scales_default)

    if facet_fun == "facet_grid"
        return facet_grid(facet_args["facets"], scales = facet_args["scales"])
    else
        return facet_wrap(facet_args["facets"], scales = facet_args["scales"])
    end
end


function error_label()
    return L"\textit{y} - \textit{y}_\text{rep}"
end

function error_avg_label()
    return L"\text{Average } \textit{y} - \textit{y}_\text{rep"
end


function ppc_error_binned_data(y, yrep, bins=nothing)
    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))

    if isnothing(bins)
        bins = n_bins(length(y))
    end

    errors = compute_errors(y, yrep)
    binned_errs = []
    for s in 1:size(errors, 1)
        push!(binned_errs, bin_errors(ey=yrep[s, :], r=errors[s, :], bins=bins, rep_id=s))
    end

    binned_errs_df = vcat(binned_errs...)
    return DataFrame(binned_errs_df)
end

function n_bins(N)
    if N <= 10
        return floor(Int, N / 2)
    elseif N > 10 && N < 100
        return 10
    else # N >= 100
        return floor(Int, sqrt(N))
    end
end


function bin_errors(ey, r, bins, rep_id=nothing)
    N = length(ey)
    break_ids = floor.(Int, N * (1:(bins - 1)) / bins)
    if any(break_ids .== 0)
        bins = 1
    end
    if bins == 1
        breaks = [-Inf, sum(extrema(ey)) / 2, Inf]
    else
        ey_sort = sort(ey)
        breaks = [-Inf]
        for i in 1:(bins - 1)
            break_i = break_ids[i]
            ey_range = ey_sort[[break_i, break_i + 1]]
            if diff(ey_range)[] == 0
                if ey_range[1] == minimum(ey)
                    ey_range[1] = -Inf
                else
                    ey_range[1] = maximum(ey[ey .< ey_range[1]])
                end
            end
            append!(breaks, sum(ey_range) / 2)
        end
        breaks = unique([breaks, Inf])
    end

    ey_binned = cut(ey, breaks)
    bins = length(breaks) - 1
    out = Matrix{Union{Missing, Float64}}(missing, bins, 4)
    colnames = ["ey_bar", "err_bar", "se2", "bin"]

    for i in 1:bins
        mark = findall(x -> x == i, ey_binned)
        ey_bar = mean(ey[mark])
        r_bar = mean(r[mark])
        s = length(r[mark]) > 1 ? std(r[mark]) : 0
        out[i, :] = [ey_bar, r_bar, 2 * s / sqrt(length(mark)), i]
    end
    out_df = DataFrame(out, Symbol.(colnames))

    if !isnothing(rep_id)
        out_df.rep_id = fill(rep_id, nrow(out_df))
    end

    return out_df
end
