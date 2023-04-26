using Gadfly, DataFrames, DataFramesMeta, Colors, ColorSchemes

function theme_default(base_size = get(ENV, "bayesplot.base_size", 12),
                       base_family = get(ENV, "bayesplot.base_family", "serif"))

    Gadfly.Theme(
        background_color=Gadfly.colorant"white",
        panel_fill=Gadfly.colorant"white",
        panel_border=Gadfly.colorant"white",
        grid_color=Gadfly.colorant"white",
        major_label_font_size=base_size,
        minor_label_font_size=base_size,
        major_label_font=base_family,
        minor_label_font=base_family,
        key_position=:right,
        key_title_font_size=13,
        key_label_font_size=13,
        strip_label_font_size=base_size * 0.9,
        strip_label_font=base_family,
        strip_background_color=Gadfly.colorant"white",
        strip_stroke_color=Gadfly.colorant"white"
    )
end

function bayesplot_theme_get()
    if !haskey(ENV, "bayesplot_theme")
        theme_default()
    else
        ENV["bayesplot_theme"]
    end
end

function bayesplot_theme_set(new_theme=nothing)
    old_theme = bayesplot_theme_get()

    if new_theme === nothing
        delete!(ENV, "bayesplot_theme")
    else
        ENV["bayesplot_theme"] = new_theme
    end
    return old_theme
end

function bayesplot_theme_update(; kwargs...)
    current_theme = bayesplot_theme_get()
    new_theme = merge(current_theme, Gadfly.Theme(; kwargs...))
    return bayesplot_theme_set(new_theme)
end

function bayesplot_theme_replace(; kwargs...)
    current_theme = bayesplot_theme_get()
    new_theme = merge(current_theme, Gadfly.Theme(; kwargs...))
    return bayesplot_theme_set(new_theme)
end
