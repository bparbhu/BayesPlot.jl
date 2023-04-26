using Gadfly, DataFrames, DataFramesMeta, Colors, ColorSchemes

function vline_at(v, fun=nothing, na_rm=true)
    xintercept = fun === nothing ? v : fun(v)
    Guide.vline(xintercept=xintercept)
end

function hline_at(v, fun=nothing, na_rm=true)
    yintercept = fun === nothing ? v : fun(v)
    Guide.hline(yintercept=yintercept)
end

function vline_0(na_rm=true)
    Guide.vline(xintercept=0)
end

function hline_0(na_rm=true)
    Guide.hline(yintercept=0)
end

function abline_01(na_rm=true)
    Guide.abline(slope=1, intercept=0)
end

function lbub(p, med=true)
    x -> calc_intervals(x, p, med)
end

function calc_v(v, fun=nothing, fun_args=nothing)
    if fun === nothing
        return v
    end
    f = fun
    if fun_args === nothing
        return f(v)
    end
    return f(v, fun_args...)
end

function calc_intervals(x, p, med=true)
    a = (1 - p) / 2
    pr = [a, med ? 0.5 : 1 - a]
    quantile(x, pr)
end

function panel_bg(bgcolor)
    Theme(panel_fill=color(bgcolor))
end

function plot_bg(bgcolor)
    Theme(plot_background=color(bgcolor))
end

function grid_lines(major_color="gray50", minor_color="gray80")
    Theme(
        major_label_color=color(major_color),
        minor_label_color=color(minor_color)
    )
end

function facet_labels(fontsize=10)
    Theme(
        key_title_font_size=fontsize,
        key_label_font_size=fontsize
    )
end

function axis_labels(xlabel, ylabel, fontsize=12)
    Theme(
        x_axis_label=xlabel,
        y_axis_label=ylabel,
        major_label_font_size=fontsize
    )
end
