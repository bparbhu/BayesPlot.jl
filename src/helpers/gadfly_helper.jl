using Gadfly, DataFrames

function Geom_ignore(; kwargs...)
    return Geom.blank(
        mapping=nothing, data=nothing,
        show_legend=false, inherit_aes=false
    )
end


using Gadfly, DataFrames

function modify_aes_(mapping; kwargs...)
    return merge(mapping, aes(; kwargs...))
end

function modify_aes(mapping; kwargs...)
    return modify_aes_(mapping; kwargs...)
end


using Gadfly, DataFrames

function facet_wrap_parsed(; kwargs...)
    return facet_wrap(; kwargs..., labeller = label_parsed)
end


function dont_expand_y_axis(expand=(0, 0))
    return Scale.y_continuous(expand=expand)
end


function dont_expand_x_axis(expand=(0, 0))
    return Scale.x_continuous(expand=expand)
end


function dont_expand_axes()
    return Coord.cartesian(expand=false)
end


function force_axes_in_facets()
    thm = bayesplot_theme_get()
    return layer(
        x=[-Inf, -Inf, Inf], xend=[Inf, -Inf, Inf],
        y=[-Inf, -Inf, -Inf], yend=[-Inf, Inf, Inf],
        Geom.segment,
        Theme(line_width=thm["axis.line"]["linewidth"])
    )
end


function force_x_axis_in_facets()
    thm = bayesplot_theme_get()
    return layer(
        x=[-Inf, Inf], xend=[-Inf, Inf],
        y=[-Inf, -Inf], yend=[-Inf, -Inf],
        Geom.segment,
        Theme(line_width=thm["axis.line"]["linewidth"])
    )
end


function no_legend_spacing()
    return Theme(legend_spacing_y=0cm)
end


function reduce_legend_spacing(cm)
    return Theme(legend_spacing_y=(-cm)cm)
end


function space_legend_keys(relative_size=2, color="white")
    return Theme(legend_key=element_rect(line_width=relative_size, color=color))
end


function set_hist_aes(freq=true; kwargs...)
    if freq
        return aes(x=:value; kwargs...)
    else
        return aes(x=:value, y=Stat.density; kwargs...)
    end
end


function scale_color_ppc(; name=nothing, values=nothing, labels=nothing, kwargs...)
    name = name === nothing ? "" : name
    values = values === nothing ? get_color(["dh", "lh"]) : values
    labels = labels === nothing ? [y_label(), yrep_label()] : labels
    return Scale.color_manual(; name=name, values=values, labels=labels, kwargs...)
end


function scale_fill_ppc(; name=nothing, values=nothing, labels=nothing, kwargs...)
    name = name === nothing ? "" : name
    values = values === nothing ? get_color(["d", "l"]) : values
    labels = labels === nothing ? [y_label(), yrep_label()] : labels
    return Scale.fill_manual(; name=name, values=values, labels=labels, kwargs...)
end


function scale_color_ppd(; name=nothing, values=get_color("mh"), labels=ypred_label(), kwargs...)
    return scale_color_ppc(; name=name, values=values, labels=labels, kwargs...)
end


function scale_fill_ppd(; name=nothing, values=get_color("m"), labels=ypred_label(), kwargs...)
    return scale_fill_ppc(; name=name, values=values, labels=labels, kwargs...)
end
