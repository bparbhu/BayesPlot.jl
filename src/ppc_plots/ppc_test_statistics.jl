using Gadfly, DataFrames, DataFramesMeta, Colors, ColorSchemes, LaTeXStrings



function ppc_stat_data(y, yrep, group = nothing, stat_func)
    if length(stat_func) ∉ (1, 2)
        throw(ArgumentError("'stat_func' must have length 1 or 2."))
    end

    y = validate_y(y)
    yrep = validate_predictions(yrep, length(y))
    if !isnothing(group)
        group = validate_group(group, length(y))
    end

    if length(stat_func) == 1
        stat_func = [stat_func]
    else
        stat_func = [stat_func[1], stat_func[2]]
    end

    return _ppd_stat_data(predictions = yrep, y = y, group = group, stat = stat_func)
end


function stat_legend_title(stat, stat_txt)
    if !(isa(stat, AbstractString) || isa(stat, Function))
        throw(ArgumentError("stat must be a string or a function"))
    end

    if isa(stat, AbstractString)
        lgnd_txt = stat
    else
        lgnd_txt = length(stat_txt) == 1 && !occursin(r"^function", stat_txt) ? stat_txt : missing
    end

    if ismissing(lgnd_txt)
        return nothing
    end

    return "italic(T) == $(lgnd_txt)"
end


function stat_2d_segment_data(data)
    y_data = @where(data, :variable .== "y")
    stats = [y_data.value[1], y_data.value2[1]]
    return DataFrame(
        x = [stats[1], -Inf],
        xend = [stats[1], stats[1]],
        y = [-Inf, stats[2]],
        yend = [stats[2], stats[2]]
    )
end


function ppc_stat_2d(y, yrep, stat = ["mean", "sd"]; size = 2.5, alpha = 0.7)

    if length(stat) != 2
        throw("For ppc_stat_2d the 'stat' argument must have length 2.")
    end

    stat_labels = stat

    data = ppc_stat_data(y, yrep, nothing, stat)
    y_segment_data = stat_2d_segment_data(data)
    y_point_data = DataFrame(x = y_segment_data[1, "x"], y = y_segment_data[2, "y"])

    p = plot(data,
        layer(
            x = :value, y = :value2,
            color = :variable, fill = :variable,
            Geom.point,
            Theme(default_point_size = size, default_color = "yrep", alphas = [alpha])
        ),
        layer(
            y_segment_data,
            x = :x, y = :y, xend = :xend, yend = :yend,
            color = :variable,
            Geom.segment,
            Theme(default_linetype = "dashed", default_color = "y")
        ),
        layer(
            y_point_data,
            x = :x, y = :y,
            color = :variable, fill = :variable,
            Geom.point,
            Theme(default_point_size = size * 1.5, default_color = "y", default_shape = "circle")
        ),
        Guide.xlabel(stat_labels[1]),
        Guide.ylabel(stat_labels[2]),
        # Include your custom color and fill scales here
    )

    return p
end


function Ty_label()
    return L"T_y"
end

function Tyrep_label()
    return L"T_{y_{rep}}"
end


function ppc_stat_freqpoly(y, yrep, stat = mean; binwidth = nothing, freq = true)
    data = ppc_stat_data(y, yrep, stat = stat)

    filtered_data = @where(data, :variable .!= "y")
    vline_data = @where(data, :variable .== "y")

    p = plot(
        filtered_data,
        x=:value, color=:variable,
        Geom.histogram(binwidth=binwidth, density=freq, position=:dodge),
        Guide.colorkey(title=stat_legend_title(stat)),
        Theme(panel_fill=colorant"white")
    )

    return p
end

function ppc_stat_freqpoly_grouped(y, yrep, group, stat = mean; binwidth = nothing, freq = true)
    p = ppc_stat_freqpoly(y, yrep, stat = stat, binwidth = binwidth, freq = freq)
    return p
end


function ppc_stat(y, yrep, stat = mean; group = nothing, binwidth = nothing, freq = true)
    data = ppc_stat_data(y, yrep, group = group, stat = stat)

    filtered_data = @where(data, :variable .!= "y")
    vline_data = @where(data, :variable .== "y")

    p = plot(
        filtered_data,
        x=:value, color=:variable,
        Geom.histogram(binwidth=binwidth, density=freq),
        Geom.vline(xintercept = vline_data.value),
        Guide.colorkey(title=stat_legend_title(stat)),
        Theme(panel_fill=colorant"white")
    )

    return p
end


function ppc_stat_grouped(y, yrep, group, stat = mean; binwidth = nothing, freq = true, facet_args = [])
    p = ppc_stat(y, yrep, stat = stat, group = group, binwidth = binwidth, freq = freq)
    ungrouped_p = ppc_stat(y, yrep, stat = stat, group = nothing, binwidth = binwidth, freq = freq)
    facet_p = compose(p, ungrouped_p, context = :facets)
    return facet_p
end

