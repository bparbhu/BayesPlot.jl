using DataFrames, DataFramesMeta, Gadfly, Stan, Colors


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

    if size(yrep, 1) == 1
        facet_layer = Geom.blank()  # equivalent to geom_ignore()
    else
        facet_args["facets"] = "rep_label"
        facet_layer = Facet.wrap(; facet_args...)
    end

    scatter_plot = plot(data,
        layer(x=:y_rep, y=:y_obs, color=:rep_label, Geom.point, Theme(point_size=size, point_alpha=alpha)),
        layer(xintercept=[0], Geom.vline, Theme(line_width=1.5, default_color="gray"), show=ref_line),
        Scale.color_discrete_manual("red"),
        Theme(panel_stroke=colorant"gray"),
        Coord.cartesian(fixed=true),
        facet_layer,
        Guide.xlabel("y_rep"), Guide.ylabel("y"),
        Guide.xticks(ticks=nothing), Guide.yticks(ticks=nothing),
        Guide.title(""))
    return scatter_plot
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


function ppc_scatter_avg_grouped(y, yrep, group; size=2.5, alpha=0.8, ref_line=true, facet_args=Dict())
    scatter_avg_plot = ppc_scatter_avg(y, yrep, size=size, alpha=alpha, ref_line=ref_line, group=group)
    facet_layer = layer(Facet.Grid(group, orientation=:vertical, key=:group), Theme(grid_line_width=1px, grid_color=colorant"gray"))
    
    return scatter_avg_plot * facet_layer
end


function yrep_avg_label()
    return "Average " * "y[rep]"
end


function scatter_aes(;kwargs...)
    return (x=:value, y=:y_obs, kwargs...)
end


function scatter_avg_group_facets(;facet_args=Dict())
    facet_args[:facets] = :group
    facet_args[:scales] = get(facet_args, :scales, :free)
    return layer(Facet.Grid(:group, scales=facet_args[:scales]), Theme(grid_line_width=1px, grid_color=colorant"gray"))
end


function scatter_ref_line(ref_line=true; linetype=2, color=colorant"gray", kwargs...)
    if !ref_line
        return layer(Theme(grid_line_width=0px))
    end
    return layer(xintercept=[0,1], Geom.vline(color=color, style=linetype))
end
