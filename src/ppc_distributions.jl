using Stan
using Gadfly
using DataFrames
using Random
using StatsBase
using KernelDensity, Distributions


function ppc_data(y::Vector, yrep::Matrix, group::Union{Vector, Nothing}=nothing)
    n = length(y)
    m = size(yrep, 1)
    
    if group === nothing
        df = DataFrame(y=repeat(y, outer=m), yrep=vec(yrep))
    else 
        if length(group) != n
            throw(ArgumentError("Length of group must match the length of y"))
        end
        df = DataFrame(y=repeat(y, outer=m), yrep=vec(yrep), group=repeat(group, outer=m))
    end
    return df
end


function ppc_dens_overlay(y::Vector, yrep::Matrix;
                          size=0.25, alpha=0.7, trim=false, bw="nrd0", adjust=1, kernel="gaussian", n_dens=1024)

    # Prepare data
    df = ppc_data(y, yrep)
    
    # Calculate density estimates for observed data
    y_density = kde(y, bandwidth=bw, adjust=adjust, kernel=kernel)
    
    # Calculate density estimates for replicated data
    yrep_density = kde(vec(yrep), bandwidth=bw, adjust=adjust, kernel=kernel)
    
    # Overlay densities
    p = plot(layer(x=y_density.x, y=y_density.density, Geom.line, Theme(default_color=colorant"blue")),
             layer(x=yrep_density.x, y=yrep_density.density, Geom.line, Theme(default_color=colorant"red", line_style=:dot, line_width=size, alpha=alpha)))
    
    return p
end


function ppc_dens_overlay_grouped(y::Vector, yrep::Matrix, group::Vector;
                                  size=0.25, alpha=0.7, trim=false, bw="nrd0", adjust=1, kernel="gaussian", n_dens=1024)
    
    # Prepare data
    df = ppc_data(y, yrep, group)
    
    # Get unique group values
    unique_groups = unique(group)

    # Create plot
    p = plot()

    # Plot density for each group
    for g in unique_groups
        y_group = df.y[df.group .== g]
        yrep_group = df.yrep[df.group .== g]

        y_density = kde(y_group, bandwidth=bw, adjust=adjust, kernel=kernel)
        yrep_density = kde(yrep_group, bandwidth=bw, adjust=adjust, kernel=kernel)
        
        # Overlay densities for the observed and replicated data of the current group
        p = plot(p,
                 layer(x=y_density.x, y=y_density.density, Geom.line, Theme(default_color=colorant"blue")),
                 layer(x=yrep_density.x, y=yrep_density.density, Geom.line, Theme(default_color=colorant"red", line_style=:dot, line_width=size, alpha=alpha)))
    end
    
    return p
end


function ppc_ecdf_overlay(y::Vector, yrep::Matrix; discrete=false, pad=true, size=0.25, alpha=0.7)
    
    # Prepare data
    df = ppc_data(y, yrep)
    
    # Create plot
    p = plot()

    # Calculate ECDF for y and yrep
    y_ecdf = ecdf(y)
    yrep_ecdf = [ecdf(yrep[:, i]) for i in 1:size(yrep, 2)]

    x_vals = sort(union(y, vec(yrep)))

    if pad
        x_vals = vcat([2 * x_vals[1] - x_vals[2]], x_vals, [2 * x_vals[end] - x_vals[end-1]])
    end

    y_vals = y_ecdf.(x_vals)
    yrep_vals = [mean(yrep_ecdf_i.(x_vals)) for yrep_ecdf_i in yrep_ecdf]

    if discrete
        y_vals = vcat(0, y_vals[1:end-1])
        yrep_vals = vcat(0, yrep_vals[1:end-1])
    end

    # Overlay ECDFs for observed and replicated data
    p = plot(p,
             layer(x=x_vals, y=y_vals, Geom.step, Theme(default_color=colorant"blue", line_width=size)),
             layer(x=x_vals, y=yrep_vals, Geom.step, Theme(default_color=colorant"red", line_width=size, alpha=alpha)))

    return p
end


function ppc_ecdf_overlay_grouped(y::Vector, yrep::Matrix, group::Vector; discrete=false, pad=true, size=0.25, alpha=0.7)
    unique_groups = unique(group)

    # Create plot
    p = plot()

    for g in unique_groups
        group_indices = findall(group .== g)
        y_group = y[group_indices]
        yrep_group = yrep[group_indices, :]

        p_ecdf_overlay = ppc_ecdf_overlay(y_group, yrep_group, discrete=discrete, pad=pad, size=size, alpha=alpha)
        p = plot(p, p_ecdf_overlay)
    end

    return p
end


function ppc_dens(y::Vector, yrep::Matrix; trim=false, size=0.5, alpha=1)
    # Calculate the density for y
    y_density = kde(y)

    # Calculate the densities for yrep
    yrep_densities = [kde(yrep[:, i]) for i in 1:size(yrep, 2)]

    # Combine the densities
    combined_densities = [y_density; yrep_densities]

    # Trim the densities if required
    if trim
        min_x = minimum([minimum(d.x) for d in combined_densities])
        max_x = maximum([maximum(d.x) for d in combined_densities])
        combined_densities = [trim_density(d, min_x, max_x) for d in combined_densities]
    end

    # Create the plot
    p = plot(
        layer(x=combined_densities[1].x, y=combined_densities[1].density, Geom.line, Theme(default_color="black", line_width=size, alphas=[alpha])),
        [layer(x=d.x, y=d.density, Geom.line, Theme(line_width=size, alphas=[alpha])) for d in combined_densities[2:end]]...
    )
    return p
end


function trim_density(density, min_x, max_x)
    x_indices = (density.x .>= min_x) .& (density.x .<= max_x)
    return (x=density.x[x_indices], density=density.density[x_indices])
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


function ppc_freqpoly(y::Vector, yrep::Matrix; binwidth=nothing, freq=true, size=0.5, alpha=1)
    yrep_flat = vec(yrep)

    # Calculate bins
    if binwidth === nothing
        bin_edges = StatsBase.auto_histogram(yrep_flat, :sqrt)[:edges]
    else
        bin_edges = minimum(yrep_flat):binwidth:maximum(yrep_flat)
    end

    # Calculate densities
    y_density = kde(y, :gaussian, bin_edges)
    yrep_density = kde(yrep_flat, :gaussian, bin_edges)

    # Normalize if needed
    if freq
        y_density = normalize_density_to_frequency!(y_density, y)
        yrep_density = normalize_density_to_frequency!(yrep_density, yrep_flat)
    end

    # Create a DataFrame with data for the plot
    plot_data = DataFrame()
    plot_data[:x] = y_density.x
    plot_data[:yrep_density] = yrep_density.density
    plot_data[:y_density] = y_density.density

    # Create the plot
    p = plot(
        plot_data,
        x=:x,
        y=:yrep_density,
        Geom.line,
        Theme(line_width=size, default_color=colorant"gray", alphas=[alpha]),
        layer(x=:x, y=:y_density, Geom.line, Theme(line_width=size, default_color="black", alphas=[alpha]))
    )
    return p
end

function normalize_density_to_frequency!(density, data::AbstractVector)
    area = trapz(density.x, density.density)
    density.density ./= area
    density.density .*= length(data)
    return density
end


function ppc_freqpoly_grouped(y::Vector, yrep::Matrix, group::Vector; binwidth=nothing, freq=true, size=0.5, alpha=1)
    unique_groups = unique(group)
    n_groups = length(unique_groups)

    # Initialize plot
    plot_layers = []

    # Iterate through unique groups and plot each group
    for (group_index, group_value) in enumerate(unique_groups)
        group_mask = group .== group_value
        y_group = y[group_mask]
        yrep_group = yrep[group_mask, :]

        # Call ppc_freqpoly for each group and add to plot_layers
        group_plot = ppc_freqpoly(y_group, yrep_group; binwidth=binwidth, freq=freq, size=size, alpha=alpha)
        push!(plot_layers, group_plot.layers[1])
        push!(plot_layers, group_plot.layers[2])
    end

    # Create a combined plot with all layers
    p = plot(plot_layers..., Guide.title("Frequency Polygon by Group"))
    return p
end


function ppc_boxplot(y::Vector, yrep::Matrix; notch=true, size=0.5, alpha=1)
    n_yrep = size(yrep, 2)

    # Combine y and yrep into a single DataFrame for plotting
    df_y = DataFrame(value = y, variable = fill("Observed", length(y)), group = 1:length(y))
    df_yrep = hcat(DataFrame(value = vec(yrep), group = repeat(1:length(y), inner = n_yrep)), :variable => fill("Replicated", size(yrep, 1) * n_yrep))
    df = vcat(df_y, df_yrep)

    # Plot the boxplot with Gadfly
    p = plot(df, x = "group", y = "value", color = "variable",
             Geom.boxplot(notch = notch),
             Theme(default_color = colorant"orange", alphas = [alpha], discrete_highlight_color = (c, alpha) -> c),
             Guide.title("Boxplot of Observed and Replicated Data"),
             Guide.xlabel("Group"), Guide.ylabel("Value"))
    return p
end


function ppc_violin_grouped(y::Vector, yrep::Matrix, group::Vector; probs = [0.1, 0.5, 0.9], size = 1, alpha = 1, y_draw = "violin", y_size = 1, y_alpha = 1, y_jitter = 0.1)
    n_yrep = size(yrep, 2)

    # Combine y, yrep, and group into a single DataFrame for plotting
    df_y = DataFrame(value = y, variable = fill("Observed", length(y)), group = group)
    df_yrep = hcat(DataFrame(value = vec(yrep), group = repeat(group, inner = n_yrep)), :variable => fill("Replicated", size(yrep, 1) * n_yrep))
    df = vcat(df_y, df_yrep)

    layers = []

    # Add violin layer
    if y_draw == "violin" || y_draw == "both"
        push!(layers, layer(df, x = "group", y = "value", color = "variable", Geom.violin, Theme(alphas = [alpha], discrete_highlight_color = (c, alpha) -> c)))
    end

    # Add points layer
    if y_draw == "points" || y_draw == "both"
        push!(layers, layer(df, x = "group", y = "value", color = "variable", Geom.point, Theme(default_point_size = y_size, alphas = [y_alpha], discrete_highlight_color = (c, y_alpha) -> c), position = Pos.position_jitter(0, y_jitter)))
    end

    # Plot the grouped violin plot with Gadfly
    p = plot(layers...,
             Guide.title("Violin Plot of Observed and Replicated Data Grouped"),
             Guide.xlabel("Group"), Guide.ylabel("Value"))

    return p
end


function ppc_pit_ecdf(y::Vector, yrep::Matrix; pit = nothing, K = nothing, prob = 0.99, plot_diff = false, interpolate_adj = nothing)
    n = length(y)
    n_yrep = size(yrep, 2)

    # Compute PIT values if not provided
    if pit === nothing
        pit = zeros(n)
        for i in 1:n
            pit[i] = sum(yrep[i, :] .<= y[i]) / n_yrep
        end
    end

    # Compute K if not provided
    if K === nothing
        K = Int(ceil(-log10(1 - prob)))
    end

    # Compute interpolated_adj if not provided
    if interpolate_adj === nothing
        interpolate_adj = 1 / (n_yrep + 1)
    end

    # Compute differences in PIT values
    if plot_diff
        pit = pit .- (0.5:1/n:1-1/n)
    end

    # Create a DataFrame for plotting
    df = DataFrame(pit = pit, index = (1:n) ./ n)

    # Create the ECDF plot with Gadfly
    p = plot(df, x = "pit", y = "index", Geom.path, Geom.ribbon(interpolate_adj),
             Guide.title("PIT ECDF Plot"), Guide.xlabel("PIT Value"), Guide.ylabel("Empirical CDF"))

    return p
end


function ppc_pit_ecdf_grouped(y::Vector, yrep::Matrix, group::Vector; K = nothing, pit = nothing, prob = 0.99, plot_diff = false, interpolate_adj = nothing)
    n = length(y)
    n_yrep = size(yrep, 2)
    unique_groups = unique(group)

    # Compute PIT values if not provided
    if pit === nothing
        pit = zeros(n)
        for i in 1:n
            pit[i] = sum(yrep[i, :] .<= y[i]) / n_yrep
        end
    end

    # Compute K if not provided
    if K === nothing
        K = Int(ceil(-log10(1 - prob)))
    end

    # Compute interpolated_adj if not provided
    if interpolate_adj === nothing
        interpolate_adj = 1 / (n_yrep + 1)
    end

    # Compute differences in PIT values
    if plot_diff
        pit = pit .- (0.5:1/n:1-1/n)
    end

    # Create a DataFrame for plotting
    df = DataFrame(pit = pit, index = (1:n) ./ n, group = group)

    # Create the grouped ECDF plot with Gadfly
    p = plot(df, x = "pit", y = "index", color = "group", Geom.subplot_grid(Geom.path, free_y_axis = true), Guide.title("Grouped PIT ECDF Plot"), Guide.xlabel("PIT Value"), Guide.ylabel("Empirical CDF"))

    return p
end

