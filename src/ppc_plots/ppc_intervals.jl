using Gadfly, Stan, DataFrames
include("ppc_helpers.jl")


function ppc_intervals_data(y, yrep; x=nothing, group=nothing, prob=0.5, prob_outer=0.9)
    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))
    x = validate_x(x, y)
    if !isnothing(group)
        group = validate_group(group, length(y))
    end
    return ppd_intervals_data(predictions=yrep, y=y, x=x, group=group, prob=prob, prob_outer=prob_outer)
end

ppc_ribbon_data = ppc_intervals_data


function ppc_intervals(y, yrep; x=nothing, prob=0.5, prob_outer=0.9, alpha=0.33, size=1, fatten=2.5, linewidth=1, group=nothing)
    if !from_grouped(group)
        check_ignored_arguments(group)
        group = nothing
    end

    data = ppc_intervals_data(y=y, yrep=yrep, x=x, group=group, prob=prob, prob_outer=prob_outer)

    p = plot(data,
        layer(
            intervals_inner_aes(needs_y=true, color="yrep", fill="yrep"),
            Geom.linerange,
            Theme(default_color=colorant"yrep", alphas=[alpha], line_width=[size, linewidth])
        ),
        layer(
            intervals_outer_aes(color="yrep"),
            Geom.pointrange,
            Theme(default_color=colorant"yrep", line_width=[size, linewidth], point_size=[size], point_fatten=[fatten])
        ),
        layer(
            x=:y_obs, color="y", fill="y",
            Geom.point,
            Theme(default_color=colorant"y", default_point_size=1)
        ),
        Guide.xlabel(has_x ? "x" : ""),
        Guide.ylabel("y"),
        Theme(line_width=[size, linewidth])
    )
    return p
end


function ppc_intervals_grouped(y, yrep, group; x=nothing, facet_args=Dict(), prob=0.5, prob_outer=0.9, alpha=0.33, size=1, fatten=2.5, linewidth=1)
    check_ignored_arguments(facet_args)

    g = ppc_intervals(y, yrep; x=x, group=group, prob=prob, prob_outer=prob_outer, alpha=alpha, size=size, fatten=fatten, linewidth=linewidth)

    g_with_facets = plot(g, facet_args)
    return g_with_facets
end


function ppc_ribbon(y, yrep; x=nothing, prob=0.5, prob_outer=0.9, alpha=0.33, size=0.25, y_draw=:both, group=nothing)

    data = ppc_intervals_data(y, yrep; x=x, group=group, prob=prob, prob_outer=prob_outer)

    g = plot(data,
        layer(Geom.ribbon, intervals_outer_aes(fill = "yrep", color = "yrep"), Theme(line_width = 0.2 * size, alpha = alpha)),
        layer(Geom.ribbon, intervals_outer_aes(), Theme(fill = nothing, line_color = get_color("m"), line_width = 0.2 * size, alpha = 1)),
        layer(Geom.ribbon, Theme(line_width = 0.5 * size)),
        layer(Geom.line, aes(y = :m), Theme(line_color = get_color("m"), line_width = size)),
        Geom.blank(aes(fill = "y")),
        Scale.color_ppc(),
        Scale.fill_ppc(values = Dict("NA" => nothing, "l" => get_color("l")), na_value = nothing),
        intervals_axis_labels(has_x = !isnothing(x))
    )

    if y_draw in (:line, :both)
        g = plot!(g, Geom.line(aes(y = :y_obs, color = "y"), Theme(line_width = 0.5)))
    end

    if y_draw in (:points, :both)
        g = plot!(g, Geom.point(aes(y = :y_obs, color = "y", fill = "y"), shape = 21, size = 1.5))
    end

    return g
end


function ppc_ribbon_grouped(y, yrep; x=nothing, group=nothing, prob=0.5, prob_outer=0.9, alpha=0.33, size=0.25, y_draw=:both, facet_args=Dict())

    g = ppc_ribbon(y, yrep; x=x, group=group, prob=prob, prob_outer=prob_outer, alpha=alpha, size=size, y_draw=y_draw)

    g = plot(g, intervals_group_facets(facet_args))
    g = force_axes_in_facets(g)

    return g
end
