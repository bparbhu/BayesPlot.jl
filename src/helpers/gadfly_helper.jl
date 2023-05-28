using Gadfly, DataFrames


function Geom_ignore(p::Plot; kwargs...)
    geom_blank_layer = layer(
        Geom.blank(),
        mapping=nothing, data=nothing,
        show_legend=false, inherit_aes=false
    )
    push!(p, geom_blank_layer)
    
    return p
end


function modify_aes_(p::Plot, mapping; kwargs...)
    new_mapping = merge(mapping, aes(; kwargs...))
    for layer in p.layers
        layer.mapping = new_mapping
    end
    return p
end

function modify_aes(p::Plot, mapping; kwargs...)
    return modify_aes_(p, mapping; kwargs...)
end



function label_value(labels, multi_line = true)
    labels = map(string, labels)
    if multi_line
        return labels
    else
        return join(labels, "\n")
    end
end

function label_parsed(labels, multi_line = true)
    labels = label_value(labels, multi_line = multi_line)
    if multi_line
        return [Meta.parse(val) for val in labels]
    else
        return [Meta.parse("list($val)") for val in labels]
    end
end


function facet_wrap_parsed(p::Plot, labels; multi_line=true)
    parsed_labels = label_parsed(labels, multi_line)
    
    # Apply parsed labels as layout in Geom.subplot_grid
    push!(p, layer(Geom.subplot_grid(layout_x=parsed_labels)))
    
    return p
end


function dont_expand_y_axis(p::Plot, expand=(0, 0))
    return plot(p, Scale.y_continuous(expand=expand))
end


function dont_expand_x_axis(p::Plot, expand=(0, 0))
    return plot(p, Scale.x_continuous(expand=expand))
end


function dont_expand_axes(p::Plot)
    return plot(p, Coord.cartesian(expand=false))
end


function force_axes_in_facets(p::Plot)
    thm = bayesplot_theme_get()
    force_axes_layer = layer(
        x=[-Inf, -Inf, Inf], xend=[Inf, -Inf, Inf],
        y=[-Inf, -Inf, -Inf], yend=[-Inf, Inf, Inf],
        Geom.segment,
        Theme(line_width=thm["axis.line"]["linewidth"])
    )
    push!(p, force_axes_layer)
    return p
end


function force_x_axis_in_facets(p::Plot)
    thm = bayesplot_theme_get()
    force_x_axis_layer = layer(
        x=[-Inf, Inf], xend=[-Inf, Inf],
        y=[-Inf, -Inf], yend=[-Inf, -Inf],
        Geom.segment,
        Theme(line_width=thm["axis.line"]["linewidth"])
    )
    push!(p, force_x_axis_layer)
    return p
end


function no_legend_spacing(p::Plot)
    push!(p, Theme(legend_spacing_y=0cm))
    return p
end


function reduce_legend_spacing(p::Plot, cm)
    push!(p, Theme(legend_spacing_y=(-cm)cm))
    return p
end


function space_legend_keys(p::Plot, relative_size=2, color="white")
    push!(p, Theme(legend_key=element_rect(line_width=relative_size, color=color)))
    return p
end


function set_hist_aes(p::Plot, freq=true; kwargs...)
    if freq
        mappings = aes(x=:value; kwargs...)
        push!(p, layer(x=mappings[:x], y=mappings[:y], Geom.histogram, Theme(kwargs...)))
    else
        mappings = aes(x=:value, y=Stat.density; kwargs...)
        push!(p, layer(x=mappings[:x], y=mappings[:y], Geom.histogram, Stat.density, Theme(kwargs...)))
    end
    return p
end


function scale_color_ppc(p::Plot; name=nothing, values=nothing, labels=nothing, kwargs...)
    name = name === nothing ? "" : name
    values = values === nothing ? get_color(["dh", "lh"]) : values
    labels = labels === nothing ? [y_label(), yrep_label()] : labels
    p = plot(p, Scale.color_discrete_manual(values...; name=name, labels=labels, kwargs...))
    return p
end


function scale_fill_ppc(p::Plot; name=nothing, values=nothing, labels=nothing, kwargs...)
    name = name === nothing ? "" : name
    values = values === nothing ? get_color(["d", "l"]) : values
    labels = labels === nothing ? [y_label(), yrep_label()] : labels
    p = plot(p, Scale.fill_discrete_manual(values...; name=name, labels=labels, kwargs...))
    return p
end


function scale_color_ppd(p::Plot; name=nothing, values=get_color("mh"), labels=ypred_label(), kwargs...)
    return scale_color_ppc(p; name=name, values=values, labels=labels, kwargs...)
end


function scale_fill_ppd(p::Plot; name=nothing, values=get_color("m"), labels=ypred_label(), kwargs...)
    return scale_fill_ppc(p; name=name, values=values, labels=labels, kwargs...)
end

