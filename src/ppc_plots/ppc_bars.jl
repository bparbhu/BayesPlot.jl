using Gadfly, DataFrames, StatsBase


function ppc_bars_data(y::Vector, yrep::Matrix; group = nothing, prob = 0.9, freq = true)
    bins = fit(Histogram, y, nbins = :sqrt)
    yrep_hist = [fit(Histogram, yrep[:, i], bins.edges[1]) for i in 1:size(yrep, 2)]

    if group === nothing
        group = fill("All", length(y))
    end

    df = DataFrame()

    for (i, h) in enumerate(yrep_hist)
        counts = freq ? h.weights : h.weights / sum(h.weights)
        lower = quantile(counts, (1 - prob) / 2)
        upper = quantile(counts, 1 - (1 - prob) / 2)
        tmp_df = DataFrame(bin_mid = h.edges[1][1:end-1] .+ diff(h.edges[1]) / 2, counts = counts, lower = lower, upper = upper, group = group, yrep = fill("Yrep $i", length(counts)))
        append!(df, tmp_df)
    end

    return df
end


function ppc_bars(y::Vector, yrep::Matrix; prob = 0.9, width = 0.9, size = 1, fatten = 2.5, linewidth = 1, freq = true)
    df = ppc_bars_data(y, yrep, prob = prob, freq = freq)

    p = plot(df, x = "bin_mid", y = "counts", color = "yrep", Geom.bar(position = :dodge, dodge = width), Geom.hline(yintercept = "lower", style = :dot, size = linewidth), Geom.hline(yintercept = "upper", style = :dot, size = linewidth), Guide.title("PPC Bars"), Guide.xlabel("Y"), Guide.ylabel(freq ? "Frequency" : "Density"))

    return p
end


function ppc_bars_grouped(y::Vector, yrep::Matrix, group::Vector; prob = 0.9, width = 0.9, size = 1, fatten = 2.5, linewidth = 1, freq = true)
    df = ppc_bars_data(y, yrep, group = group, prob = prob, freq = freq)

    p = plot(df, x = "bin_mid", y = "counts", color = "yrep", Geom.subplot_grid(Geom.bar(position = :dodge, dodge = width), Geom.hline(yintercept = "lower", style = :dot, size = linewidth), Geom.hline(yintercept = "upper", style = :dot, size = linewidth), free_y_axis = true), group = "group", Guide.title("PPC Bars Grouped"), Guide.xlabel("Y"), Guide.ylabel(freq ? "Frequency" : "Density"))

    return p
end


function ppc_rootogram(y::Vector, yrep::Matrix; style = "standing", prob = 0.9, size = 1)
    df = ppc_bars_data(y, yrep, prob = prob, freq = true)

    if style == "standing"
        transform_y = identity
    elseif style == "hanging"
        transform_y = x -> -x
    elseif style == "suspended"
        transform_y = x -> 2 * x
    else
        throw(ArgumentError("Invalid style, choose one of 'standing', 'hanging', or 'suspended'"))
    end

    p = plot(df,
        x = "bin_mid",
        y = :counts,
        color = "yrep",
        Geom.line(size = size),
        Geom.point(size = size),
        Coord.cartesian(ymax = transform_y(1.1 * maximum(df.counts))),
        Guide.title("PPC Rootogram"),
        Guide.xlabel("Y"),
        Guide.ylabel("Square root of frequency"),
        Scale.y_continuous(transform = transform_y))

    return p
end
