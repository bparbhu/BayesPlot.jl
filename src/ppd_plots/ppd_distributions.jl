using DataFrames, DataFramesMeta, Gadfly
include("ppc_plots/ppc_helpers.jl")
include("helpers/bayesplot_helpers.jl")
include("helpers/bayesplot_gadfly_themes.jl")
include("helpers/gadfly_helper.jl")


function ppd_melt_and_stack(y, yrep)
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

function ppd_melt_predictions(predictions)
    obs_names = propertynames(predictions)

    molten_preds = @chain predictions begin
        stack(_, Not(:rep_id))
        rename(_, :variable => :y_id, :value => :value)
        transform(_, :y_id => (y_id -> indexin(y_id, obs_names)) => :y_id, :rep_id => :rep_id)
        transform(_, :y_id => ByRow(getindex.(obs_names, Ref(:y_id))) => :y_name, :rep_id => :rep_label)
    end

    return molten_preds
end

function ppd_data(predictions; y=nothing, group=nothing)
    if y !== nothing
        data = ppd_melt_and_stack(y, predictions)
    else
        data = ppd_melt_predictions(predictions)
        data.rep_label = replace.(data.rep_label, "rep" => "pred")
    end

    if group !== nothing
        group_indices = DataFrame(group = group, y_id = 1:length(group))
        data = @chain data begin
            leftjoin(_, group_indices, on=:y_id)
            select(_, :group, Not(:y_id))
        end
    end

    return data
end


function ppd_dens_overlay(ypred;
                          size=0.25,
                          alpha=0.7,
                          trim=false,
                          bw="nrd0",
                          adjust=1,
                          kernel="gaussian",
                          n_dens=1024)

    data = ppd_data(ypred)

    # overlay_ppd_densities, scale_color_ppd, get_color, bayesplot_theme_get, 
    # dont_expand_axes, yaxis_title, xaxis_title, yaxis_text, yaxis_ticks, and legend_none

    plot(data,
        x=:value,
        layer(overlay_ppd_densities(group=:rep_id, color="ypred",
                                     linewidth=size, alpha=alpha,
                                     trim=trim, bw=bw, adjust=adjust,
                                     kernel=kernel, n=n_dens)),
        scale_color_ppd(values=get_color("m"),
                        guide=Guide.legend(override_aes=[size=2*size, alpha=1])),
        bayesplot_theme_get(),
        dont_expand_axes(),
        yaxis_title(false),
        xaxis_title(false),
        yaxis_text(false),
        yaxis_ticks(false),
        legend_none()
    )
end


function ppd_ecdf_overlay(ypred;
                          discrete=false,
                          pad=true,
                          size=0.25,
                          alpha=0.7)

    data = ppd_data(ypred)

    # Note: You will need to define the following custom functions in Julia:
    # hline_at, stat_ecdf, scale_color_ppd, get_color, bayesplot_theme_get, 
    # yaxis_title, xaxis_title, and legend_none

    plot(data,
        x=:value,
        layer(hline_at([0, 0.5, 1],
                       linewidth=[0.2, 0.1, 0.2],
                       linetype=2,
                       color=get_color("dh"))),
        stat_ecdf(group=:rep_id,
                  color="ypred",
                  geom=discrete ? "step" : "line",
                  linewidth=size,
                  alpha=alpha,
                  pad=pad),
        scale_color_ppd(values=get_color("m"),
                        guide=Guide.legend(override_aes=[linewidth=2*size, alpha=1])),
        Scale.y_continuous(breaks=[0, 0.5, 1]),
        bayesplot_theme_get(),
        yaxis_title(false),
        xaxis_title(false),
        legend_none()
    )
end



function ppd_boxplot(ypred; notch=true, size=0.5, alpha=1.0)
    
    data = ppd_data(ypred)

    p = plot(data, 
        x=:rep_label, 
        y=:value, 
        color=fill("ypred", nrow(data)), 
        Geom.boxplot(
            notch=notch,
            linewidth=size,
            alpha=alpha,
            outlier_color="lh",
            outlier_alpha=2/3,
            outlier_size=1
        ),
        Guide.title("Your title here"),
        Guide.xlabel("X-axis Label"),   # Label for x-axis
        Guide.ylabel("Y-axis Label"),   # Label for y-axis
        Guide.xticks(ticks=nothing),   # Hide x-ticks
        Guide.yticks(ticks=nothing),   # Hide y-ticks
        Theme(major_label_font_size=0pt) # Hide axis labels
    )
    return p
end


function ppd_freqpoly(ypred; binwidth=nothing, freq=true, size=0.5, alpha=1.0, group=nothing)
    
    data = ppd_data(ypred, group=group)
    
    aes_mapping = set_hist_aes(freq, color="ypred", fill="ypred")

    p = plot(data, aes_mapping...,
        Geom.histogram(bincount=binwidth, orientation=:vertical, density=freq),
        Theme(alphas=[alpha], line_width=size), # Setting alpha and size
        Facet.grid(:rep_label .~ .), 
        Guide.xlabel(""),
        Guide.ylabel(""),
        Guide.xticks(ticks=nothing),
        Guide.yticks(ticks=nothing),
        Guide.colorkey(title=""),
        Guide.title(""),
        Coord.cartesian(ymin=0) # To not expand the y-axis
    )

    return p
end


function ppd_freqpoly_grouped(ypred, group; binwidth=nothing, freq=true, size=0.5, alpha=1.0)

    g = ppd_freqpoly(ypred; binwidth=binwidth, freq=freq, size=size, alpha=alpha)

    p = plot(g,
        Coord.cartesian(),
        Facet.grid(:rep_label .~ group),
        Guide.xlabel("X-axis Label"),   # Add a label for x-axis if needed
        Guide.ylabel("Y-axis Label"),   # Add a label for y-axis if needed
        Theme(major_label_font_size=12pt)  # Adjust axis label font size if needed
    )
    return p
end

