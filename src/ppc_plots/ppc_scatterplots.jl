using DataFrames, DataFramesMeta, Gadfly, Stan, Colors, CategoricalArrays

include("helpers/gadfly_helpers.jl")


function ppc_scatter_data(y, yrep)
    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))

    melted_predictions = melt_predictions(yrep)
    sorted_melted_predictions = sort(melted_predictions, :y_id)

    sorted_melted_predictions[!, :y_obs] = repeat(y, outer=size(yrep, 1))

    return sorted_melted_predictions
end


function ppc_scatter_avg_data(y, yrep; group=nothing)
    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))
    if group !== nothing
        group = validate_group(group, length(y))
    end

    data = ppc_scatter_data(y, yrep' * ones(size(yrep, 2)))
    data[!, :rep_id] .= missing
    data[!, :rep_label] .= "mean(italic(y)[rep]))"

    if group !== nothing
        insertcols!(data, :group => group[data.y_id], before=:y_id)
    end

    return data
end


function ppc_scatter(y, yrep; facet_args=Dict(), size=2.5, alpha=0.8, ref_line=true)
    data = ppc_scatter_data(y, yrep)  
    
    if nrow(yrep) == 1
        facet_layer = Geom_ignore()
    else
        facet_args["facets"] = "rep_label"
        facet_layer = facet_wrap_parsed(facet_args)
    end

    p = plot(data,
              layer(
                x=:value, y=:value_rep,
                color="yrep", fill="yrep",
                Geom.point,
                Theme(
                  default_point_size=size, 
                  alphas=[alpha],
                  discrete_highlight_color=c->get_color_ppd(),
                  discrete_highlight_fill=c->get_color_ppd()
                ),
                Coord.cartesian(fixed=true)
              ),
              Guide.xlabel(yrep_label()), Guide.ylabel(y_label()),
              facet_layer,
              force_axes_in_facets(), 
              facet_text(false), 
              legend_none(),
              Theme(grid_line_width=0mm, key_position=:none)
            )

    if ref_line
        push!(p, layer(x=:value, y=:value, Geom.line, Theme(default_color=colorant"darkgray")))
    end

    return p
end


function ppc_scatter_avg(y, yrep; size=2.5, alpha=0.8, ref_line=true, group=nothing)
    if group === nothing && size(yrep, 1) == 1
        println(
            "With only 1 row in 'yrep', ppc_scatter_avg is the same as ppc_scatter."
        )
    end

    data = ppc_scatter_avg_data(y, yrep, group=group)

    scatter_avg_plot = plot(data,
        layer(x=:y_rep, y=:y_obs, color=:rep_label, Geom.point, Theme(point_size=size, point_alpha=alpha)),
        layer(xintercept=[0], Geom.vline, Theme(line_width=1.5, default_color="gray"), show=ref_line),
        Scale.color_discrete_manual("red"),
        Theme(panel_stroke=colorant"gray"),
        Coord.cartesian(fixed=true),
        Guide.xlabel("y_rep_avg"), Guide.ylabel("y"),
        Guide.xticks(ticks=nothing), Guide.yticks(ticks=nothing),
        Guide.title(""))
    return scatter_avg_plot
end


function ppc_scatter_avg_grouped(y, yrep, group; facet_args=Dict(), size=2.5, alpha=0.8, ref_line=true, p::Plot)
    g = ppc_scatter_avg(y, yrep, group; size=size, alpha=alpha, ref_line=ref_line, p=p)

    # Adding scatter_avg_group_facets and force_axes_in_facets to the plot
    scatter_avg_group_facets(ref_line, facet_args; p=g)
    force_axes_in_facets(p=g)
    
    return g
end


function yrep_avg_label()
    return "Average " * "y[rep]"
end


function scatter_aes(;kwargs...)
    return (x=:value, y=:y_obs, kwargs...)
end


function scatter_avg_group_facets(facet_args)
    facet_args["facets"] = "group"
    facet_args["scales"] = get(facet_args, "scales", "free")
    return facet_wrap_parsed(facet_args)
end


function scatter_ref_line(ref_line; ,linetype=2, color=get_color("dh"), p::Plot)
    if !ref_line
        return Geom_ignore(p)
    else
        push!(p, layer(x=[0,1], y=[0,1], Geom.line, Theme(default_color=color, default_linestyle=linetype)))
    end
end

