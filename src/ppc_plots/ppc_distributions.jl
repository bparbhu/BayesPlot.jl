using Stan
using Gadfly
using DataFrames
using Random
using StatsBase
using KernelDensity, Distributions
using DataFramesMeta, Statistics

include("ppc_helpers.jl")
include("ppd_distributions.jl")


function ppc_data(y, yrep, group = nothing)
    y = validate_y(y)
    N = length(y)
    yrep = validate_predictions(yrep, N)
    if !isnothing(group)
        group = validate_group(group, N)
    end
    return ppd_data(predictions = yrep, y = y, group = group)
end



function ppc_dens_overlay(y,
                          yrep;
                          size = 0.25,
                          alpha = 0.7,
                          trim = false,
                          bw = "nrd0",
                          adjust = 1,
                          kernel = "gaussian",
                          n_dens = 1024)

    data = ppc_data(y, yrep) 

    yrep_densities = layer(data, x = :value, group = :rep_id, Geom.density, Theme(line_width = size, default_color = "red", alphas = [alpha]), Stat.density(bandwidth = bw, adjust = adjust, kernel = kernel, n = n_dens))
    y_densities = layer(data[data.is_y, :], 
                        x = :value, Geom.density, Theme(line_width = 1, 
                        default_color = "blue", alphas = [alpha]), 
                        Stat.density(bandwidth = bw, adjust = adjust, kernel = kernel, n = n_dens))

    p = plot(yrep_densities, y_densities,
             Coord.cartesian(ymax = nothing),
             Guide.ylabel(nothing),
             Guide.xlabel(nothing),
             Guide.yticks(ticks = []))

    return p
end


function ppc_dens_overlay_grouped(y,
                                  yrep,
                                  group;
                                  size = 0.25,
                                  alpha = 0.7,
                                  trim = false,
                                  bw = "nrd0",
                                  adjust = 1,
                                  kernel = "gaussian",
                                  n_dens = 1024)

    p_overlay = ppc_dens_overlay(y, yrep, size = size, alpha = alpha, trim = trim, bw = bw, adjust = adjust, kernel = kernel, n_dens = n_dens) 

    data = ppc_data(y, yrep, group) 
    set_default_plot_data!(p_overlay, data)

    p = plot(p_overlay,
             Coord.cartesian(ymax = nothing),
             Guide.ylabel(nothing),
             Guide.xlabel(nothing),
             Guide.yticks(ticks = []),
             Scale.color_discrete_manual("red", "blue"),
             Guide.colorkey(""),
             Theme(alphas = [alpha]),
             Guide.subplots())

    return p
end


function ppc_ecdf_overlay(y, yrep;
                          discrete = false,
                          pad = true,
                          size = 0.25,
                          alpha = 0.7)

    data = ppc_data(y, yrep) 

    plot(data,
         layer(Geom.hline(yintercept = [0, 0.5, 1], color = "gray", linestyle = [:dash])),
         layer(x = :value, y = u_scale(data[.!data.is_y, :].value), group = data[.!data.is_y, :].rep_id, color = ["yrep"], Geom.line, Theme(line_width = size, alphas = [alpha])),
         layer(x = :value, y = u_scale(data[data.is_y, :].value), color = ["y"], Geom.line, Theme(line_width = 1)),
         Coord.cartesian(ymax = nothing),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.yticks(ticks = [0, 0.5, 1]),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey("")
    )
end


function ppc_ecdf_overlay_grouped(y, yrep, group;
                                  discrete = false,
                                  pad = true,
                                  size = 0.25,
                                  alpha = 0.7)

    data = ppc_data(y, yrep, group = group)
    p_overlay = ppc_ecdf_overlay(y, yrep, discrete = discrete, pad = pad, size = size, alpha = alpha)

    plot(p_overlay,
         layer(x = :value, y = u_scale(data[.!data.is_y, :].value), group = (data[.!data.is_y, :].group, data[.!data.is_y, :].rep_id), color = ["yrep"], Geom.subplot_grid(Geom.line, free_y = true), Theme(line_width = size, alphas = [alpha])),
         layer(x = :value, y = u_scale(data[data.is_y, :].value), group = data[data.is_y, :].group, color = ["y"], Geom.subplot_grid(Geom.line, free_y = true), Theme(line_width = 1)),
         Coord.cartesian(ymax = nothing),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.yticks(ticks = [0, 0.5, 1]),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey("")
    )
end


function ppc_dens(y, yrep;
                  trim = false,
                  size = 0.5,
                  alpha = 1)

    data = ppc_data(y, yrep)
    plot(data,
         layer(x = :value, color = :is_y_label, Geom.density, Theme(line_width = size, alphas = [alpha])),
         Coord.cartesian(ymin = nothing),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.yticks(ticks = []),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey("")
    )
end


function ppc_hist(y::Vector, yrep::Matrix; binwidth=nothing, breaks=nothing, freq=true)
    yrep_flat = vec(yrep)

    # Calculate bins
    if breaks === nothing && binwidth === nothing
        bin_edges = StatsBase.auto_histogram(yrep_flat, :sqrt)[:edges]
    elseif breaks !== nothing
        bin_edges = breaks
    elseif binwidth !== nothing
        bin_edges = minimum(yrep_flat):binwidth:maximum(yrep_flat)
    end

    # Calculate histograms
    y_hist = fit(Histogram, y, bin_edges, closed=:left)
    yrep_hist = fit(Histogram, yrep_flat, bin_edges, closed=:left)

    # Normalize if needed
    if !freq
        normalize!(y_hist, mode=:probability)
        normalize!(yrep_hist, mode=:probability)
    end

    # Create a DataFrame with data for the plot
    plot_data = DataFrame()
    plot_data[:x] = [string("yrep_", i) for i in 1:length(yrep_hist.edges[1]) - 1]
    plot_data[:yrep_count] = yrep_hist.weights
    plot_data[:y_count] = y_hist.weights

    # Create the plot
    p = plot(
        plot_data,
        x=:x,
        y=:yrep_count,
        color=[colorant"gray"],
        Geom.bar(position=:dodge),
        layer(x=:x, y=:y_count, Geom.bar(position=:dodge), Theme(default_color="black"))
    )
    return p
end


function ppc_freqpoly(y, yrep;
                      binwidth = nothing,
                      freq = true,
                      size = 0.5,
                      alpha = 1,
                      group = nothing)

    data = ppc_data(y, yrep, group = group) 

    if binwidth === nothing
        binwidth = Gadfly.default_discretizer(:value, data) # For automatic bin width calculation
    end

    geom_stat = freq ? Geom.histogram : Geom.histogram(density = true)

    plot(data,
         layer(x = :value, color = :is_y_label, geom_stat, Theme(line_width = size, alphas = [alpha])),
         Scale.x_continuous(minvalue = minimum(data[!, :value]), maxvalue = maximum(data[!, :value])),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.yticks(ticks = []),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey("")
    )
end


function ppc_freqpoly_grouped(y, yrep, group;
                              binwidth = nothing,
                              freq = true,
                              size = 0.5,
                              alpha = 1)

    data = ppc_data(y, yrep, group = group) 
    if binwidth === nothing
        binwidth = Gadfly.default_discretizer(:value, data) # For automatic bin width calculation
    end

    geom_stat = freq ? Geom.histogram : Geom.histogram(density = true)

    plot(data,
         layer(x = :value, color = :is_y_label, geom_stat, Theme(line_width = size, alphas = [alpha])),
         Scale.x_continuous(minvalue = minimum(data[!, :value]), maxvalue = maximum(data[!, :value])),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.yticks(ticks = []),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey(""),
         Coord.cartesian(aspect_ratio = "auto"),
         Geom.subplot_grid(:is_y_label .~ :group)
    )
end


function ppc_boxplot(y, yrep;
                     notch = true,
                     size = 0.5,
                     alpha = 1)

    data = ppc_data(y, yrep) 
    plot(data,
         x = :rep_label,
         y = :value,
         color = :is_y_label,
         Geom.boxplot(notch = notch, alpha = alpha, line_width = size),
         Scale.x_discrete(labels = x -> string(x)),
         Guide.ylabel(nothing),
         Guide.xlabel(nothing),
         Guide.xticks(ticks = []),
         Guide.yticks(ticks = []),
         Scale.color_discrete_manual("red", "blue"),
         Guide.colorkey(""),
         Coord.cartesian(aspect_ratio = "auto")
    )
end


function ppc_violin_grouped(y, yrep, group;
                            probs = [0.1, 0.5, 0.9],
                            size = 1,
                            alpha = 1,
                            y_draw = "both",
                            y_size = 1,
                            y_alpha = 1,
                            y_jitter = 0.1)

    y_draw = lowercase(y_draw)
    y_violin = y_draw in ["violin", "both"]
    y_points = y_draw in ["points", "both"]

    data = ppc_data(y, yrep, group)

    plot_theme = Theme(
        panel_fill=colorant"white",
        default_color=colorant"deepskyblue"
    )

    violin_y_layer = layer(
        data[data.is_y, :],
        x=:group,
        y=:value,
        Geom.violin,
        Theme(
            default_color=colorant"steelblue",
            alpha=y_alpha,
            key_title_color=colorant"white"
        )
    )

    jitter_y_layer = layer(
        data[data.is_y, :],
        x=:group,
        y=:value,
        Geom.point,
        Theme(
            default_point_size=y_size,
            default_color=colorant"steelblue",
            key_title_color=colorant"white"
        )
    )

    violin_yrep_layer = layer(
        data[.!data.is_y, :],
        x=:group,
        y=:value,
        Geom.violin,
        Theme(
            default_color=colorant"lightskyblue",
            alpha=alpha,
            key_title_color=colorant"white"
        )
    )

    layers = []
    if y_violin
        push!(layers, violin_y_layer)
    end
    if y_points
        push!(layers, jitter_y_layer)
    end

    push!(layers, violin_yrep_layer)

    p = plot(
        layers...,
        Coord.Cartesian(ymax = maximum(data.value)),
        plot_theme,
        Guide.ylabel(""),
        Guide.xlabel("")
    )

    return p
end


function ppc_pit_ecdf(y, yrep;
                      pit = nothing,
                      K = nothing,
                      prob = 0.99,
                      plot_diff = false,
                      interpolate_adj = nothing)

    if isnothing(pit)
        data = ppc_data(y, yrep)
        pit = [mean(row.value[row.is_y] .>= row.value[.!row.is_y]) for row in groupby(data, :y_id)]
        if isnothing(K)
            K = min(length(unique(data.rep_id)) + 1, length(pit))
        end
    else
        # Validate pit if necessary
        if isnothing(K)
            K = length(pit)
        end
    end
    N = length(pit)

    gamma = adjust_gamma(N, K, prob, interpolate_adj)
    lims = ecdf_intervals(gamma, N, K)

    plot_theme = Theme(
        panel_fill=colorant"white",
        default_color=colorant"deepskyblue"
    )

    y_values = ecdf(pit).(collect(1:K) ./ K) .- (plot_diff ? collect(1:K) ./ K : 0)

    p = plot(
        layer(x=1:K ./ K, y=y_values, color=["y" for _ in 1:K], Geom.step),
        layer(x=1:K ./ K, y=lims.upper[2:end] ./ N .- (plot_diff ? 1:K ./ K : 0), color=["yrep" for _ in 1:K], Geom.step),
        layer(x=1:K ./ K, y=lims.lower[2:end] ./ N .- (plot_diff ? 1:K ./ K : 0), color=["yrep" for _ in 1:K], Geom.step),
        plot_theme,
        Guide.ylabel(""),
        Guide.xlabel(""),
        Guide.xticks(ticks=nothing),
        Coord.Cartesian(xmax=1)
    )

    return p
end


function ppc_pit_ecdf_grouped(y, yrep, group;
                               K = nothing,
                               pit = nothing,
                               prob = 0.99,
                               plot_diff = false,
                               interpolate_adj = nothing)
    if isnothing(pit)
        data = ppc_data(y, yrep, group)
        pit = [mean(row.value[row.is_y] .>= row.value[.!row.is_y]) for row in groupby(data, :y_id)]
        if isnothing(K)
            K = length(unique(data.rep_id)) + 1
        end
    else
        # Validate pit if necessary
    end
    N = length(pit)

    gammas = [adjust_gamma(sum(group .== g), min(sum(group .== g), K), prob, interpolate_adj) for g in unique(group)]

    df_pit_group = DataFrame(pit = pit, group = group)

    @chain df_pit_group begin
        groupby(:group)
        groupmap(g -> DataFrame(
            ecdf_value = ecdf(g.pit).(range(0, 1, length = min(nrow(g), K))),
            group = g.group[1],
            lims_upper = ecdf_intervals(gamma = gammas[findfirst(==(g.group[1]), unique(group))], N = nrow(g), K = min(nrow(g), K)).upper[2:end] ./ nrow(g),
            lims_lower = ecdf_intervals(gamma = gammas[findfirst(==(g.group[1]), unique(group))], N = nrow(g), K = min(nrow(g), K)).lower[2:end] ./ nrow(g),
            x = range(0, 1, length = min(nrow(g), K))
        ))
        vcat(_...)
    end

    plot_theme = Theme(
        panel_fill=colorant"white",
        default_color=colorant"deepskyblue"
    )

    p = plot(df_pit_group,
             x=:x,
             y=(plot_diff ? :ecdf_value - :x : :ecdf_value),
             color=repeat(["y"], nrow(df_pit_group)),
             group=:group,
             Geom.step,
             Guide.ylabel(""),
             Guide.xlabel(""),
             Guide.xticks(ticks=nothing),
             plot_theme,
             Geom.subplot_grid(Geom.step),
             Coord.Cartesian(xmax=1)
             )

    return p
end
