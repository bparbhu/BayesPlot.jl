using Gadfly, DataFrames, KernelDensity

function ppc_km_overlay(y::Vector, yrep::Matrix; status_y = nothing, size = 0.25, alpha = 0.7)
    n = length(y)
    n_yrep = size(yrep, 2)

    # Create a DataFrame for plotting
    df = DataFrame()

    for i in 1:n_yrep
        ecdfe = ecdf(yrep[:, i])
        cdf_values = ecdfe.(y)
        tmp_df = DataFrame(y = y, cdf = cdf_values, yrep = fill("Yrep $i", n))
        append!(df, tmp_df)
    end

    # Create the overlay plot with Gadfly
    p = plot(df, x = "y", y = "cdf", color = "yrep", Geom.line, Guide.title("KM Overlay Plot"), Guide.xlabel("Y"), Guide.ylabel("Empirical CDF"), Theme(default_color = colorant"blue", alphas = [alpha]))

    return p
end

function ppc_km_overlay_grouped(y::Vector, yrep::Matrix, group::Vector; status_y = nothing, size = 0.25, alpha = 0.7)
    n = length(y)
    n_yrep = size(yrep, 2)
    unique_groups = unique(group)

    # Create a DataFrame for plotting
    df = DataFrame()

    for i in 1:n_yrep
        for grp in unique_groups
            grp_idx = findall(==(grp), group)
            ecdfe = ecdf(yrep[grp_idx, i])
            cdf_values = ecdfe.(y[grp_idx])
            tmp_df = DataFrame(y = y[grp_idx], cdf = cdf_values, group = grp, yrep = fill("Yrep $i", length(grp_idx)))
            append!(df, tmp_df)
        end
    end

    # Create the grouped overlay plot with Gadfly
    p = plot(df, x = "y", y = "cdf", color = "yrep", Geom.subplot_grid(Geom.line, free_y_axis = true), group = "group", Guide.title("Grouped KM Overlay Plot"), Guide.xlabel("Y"), Guide.ylabel("Empirical CDF"), Theme(default_color = colorant"blue", alphas = [alpha]))

    return p
end
