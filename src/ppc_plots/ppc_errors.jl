using Gadfly
using DataFrames


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

function ppc_error_data(y::Vector, yrep::Matrix, group::Vector = nothing)
    n = length(y)
    m = size(yrep, 2)
    y_long = repeat(y, outer = m)
    yrep_long = vec(yrep)
    error = y_long - yrep_long
    df = DataFrame(y = y_long, yrep = yrep_long, error = error)
    if group !== nothing
        group_long = repeat(group, outer = m)
        df.group = group_long
    end
    return df
end
