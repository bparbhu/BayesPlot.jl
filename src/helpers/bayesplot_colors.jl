using Gadfly, DataFrames, Colors, ColorSchemes


function color_scheme_set(scheme="blue")
    if !(typeof(scheme) <: AbstractString)
        throw(ArgumentError("scheme should be a string of length 1 or a vector of length 6."))
    end

    if length(scheme) == 1
        x = scheme_from_string(scheme)
    elseif length(scheme) == 6
        x = prepare_custom_colors(scheme)
    else
        throw(ArgumentError("scheme should be a string of length 1 or a vector of length 6."))
    end
    global bayesplot_aesthetics["scheme"] = x
    return x
end


function full_level_name(x::String)
    map = Dict(
        "l" => "light",
        "lh" => "light_highlight",
        "m" => "mid",
        "mh" => "mid_highlight",
        "d" => "dark",
        "dh" => "dark_highlight",
        "light" => "light",
        "light_highlight" => "light_highlight",
        "mid" => "mid",
        "mid_highlight" => "mid_highlight",
        "dark" => "dark",
        "dark_highlight" => "dark_highlight"
    )
    return map[x]
end


function mixed_scheme(scheme1::String, scheme2::String)
    scheme1 = color_scheme_get(scheme1)
    scheme2 = color_scheme_get(scheme2)
    scheme = Dict(
        "light" => scheme1["light"],
        "light_highlight" => scheme2["light_highlight"],
        "mid" => scheme2["mid"],
        "mid_highlight" => scheme1["mid_highlight"],
        "dark" => scheme1["dark"],
        "dark_highlight" => scheme2["dark_highlight"]
    )
    return scheme
end


function is_mixed_scheme(x::Dict{String,Colorant})
    return haskey(x, "mixed") && x["mixed"]
end


function scheme_level_names()
    return ["light", "light_highlight", "mid", "mid_highlight", "dark", "dark_highlight"]
end


function plot_scheme(scheme::String)
    if scheme === nothing
        x = color_scheme_get()
    else
        x = color_scheme_get(scheme)
    end

    color_data = DataFrame(
        name = repeat([scheme], length(x)),
        group = scheme_level_names(),
        value = ones(length(x))
    )

    plot(color_data, x=:name, y=:value, color=:group, Geom.bar,
         Scale.color_discrete_manual(values=values(x)...),
         Theme(bar_spacing=0.5, panel_fill=colorant"white",
               default_color=colorant"white", grid_line_width=0.1))
end


function color_scheme_view(schemes::Array{String,1})
    plots = [plot_scheme(scheme) for scheme in schemes]
    hstack(plots...)
end


function get_color(levels::Union{String, Array{String,1}})
    levels = full_level_name(levels)
    if !all([level ∈ scheme_level_names() for level in levels])
        throw(ArgumentError("All levels must be in scheme_level_names()"))
    end
    color_vals = color_scheme_get()
    return [color_vals[level] for level in levels]
end


function is_hex_color(color::String)
    if startswith(color, "#") && length(color) == 7
        try
            parse(Int, color[2:end], base=16)
            return true
        catch
            return false
        end
    else
        return false
    end
end


function prepare_custom_colors(scheme)
    scheme_level_names() = ["d", "dh", "l", "lh", "m", "mh"]

    if length(scheme) != 6
        error("Custom color schemes must contain exactly 6 colors.")
    end

    not_found = String[]
    for clr in scheme
        if !is_hex_color(clr) && !(clr in color_names())
            push!(not_found, clr)
        end
    end

    if !isempty(not_found)
        error("Each color must be specified as either a hexadecimal color value (e.g. '#C79999') or the name of a color (e.g. 'blue'). The following provided colors were not found: ", join(not_found, ", "))
    end

    x = Dict(zip(scheme_level_names(), scheme))
    x["scheme_name"] = "custom"
    return x
end


function get_brewer_scheme(name::String)
    scheme = ColorSchemes.get(ColorSchemes.brewer_colors, name)
    return scheme.colors
end


function color_scheme_get(scheme::Union{Nothing, String}=nothing, i::Union{Nothing, String, Array{Int,1}}=nothing)
    if !isnothing(scheme)
        scheme = scheme_from_string(scheme)
    else
        x = getfield.(Ref(bayesplot_aesthetics), "scheme")
        scheme = Dict(scheme_level_names() .=> getfield.(Ref(x), scheme_level_names()))
        setfield!(x, :mixed, getfield(x, :mixed))
        setfield!(x, :scheme_name, getfield(x, :scheme_name))
    end

    if isnothing(i)
        return scheme
    elseif isa(i, String)
        return get_color([i])
    end

    if !all([idx ∈ 1:length(scheme) for idx in i]) || length(unique(i)) != length(i)
        throw(ArgumentError("All indices must be in range and unique"))
    end
    return [scheme[idx] for idx in i]
end


function scheme_from_string(scheme::String)
    if startswith(scheme, "mix-")
        # user specified a mixed scheme (e.g., "mix-blue-red")
        to_mix = split(scheme, "-")[2:3]
        x = mixed_scheme(to_mix[1], to_mix[2])
        x["mixed"] = true
        x["scheme_name"] = scheme
        return x
    elseif startswith(scheme, "brewer-")
        # user specified a ColorBrewer scheme (e.g., "brewer-Blues")
        clr_scheme_name = replace(scheme, "brewer-" => "")
        clrs = get_brewer_scheme(clr_scheme_name)
        x = Dict(zip(scheme_level_names(), clrs))
        x["mixed"] = false
        x["scheme_name"] = scheme
        return x
    else
        # check for scheme in master_color_list
        if !haskey(master_color_list, scheme)
            throw(ArgumentError("Invalid color scheme name: $scheme"))
        end
        x = master_color_list[scheme]
        x["mixed"] = false
        x["scheme_name"] = scheme
        return x
    end
end


master_color_list = Dict(
  "blue" => ["#d1e1ec", "#b3cde0", "#6497b1", "#005b96", "#03396c", "#011f4b"],
  "brightblue" => ["#cce5ff", "#99cbff", "#4ca5ff", "#198bff", "#0065cc", "#004c99"],
  "darkgray" => ["#bfbfbf", "#999999", "#737373", "#505050", "#383838", "#0d0d0d"],
  "gray" => ["#DFDFDF", "#bfbfbf", "#999999", "#737373", "#505050", "#383838"],
  "green" => ["#d9f2e6", "#9fdfbf", "#66cc99", "#40bf80", "#2d8659", "#194d33"],
  "orange" => ["#fecba2", "#feb174", "#fe8a2f", "#e47115", "#b15810", "#7f3f0c"],
  "pink" => ["#dcbccc", "#c799b0", "#b97c9b", "#a25079", "#8f275b", "#7c003e"],
  "purple" => ["#e5cce5", "#bf7fbf", "#a64ca6", "#800080", "#660066", "#400040"],
  "red" => ["#DCBCBC", "#C79999", "#B97C7C", "#A25050", "#8F2727", "#7C0000"],
  "teal" => ["#bcdcdc", "#99c7c7", "#7cb9b9", "#50a2a2", "#278f8f", "#007C7C"],
  "yellow" => ["#fbf3da", "#f8e8b5", "#f5dc90", "#dbc376", "#aa975c", "#7a6c42"],
  "viridis" => ["#FDE725FF", "#7AD151FF", "#22A884FF", "#2A788EFF", "#414487FF", "#440154FF"],
  "viridisA" => ["#FCFDBFFF", "#FE9F6DFF", "#DE4968FF", "#8C2981FF", "#3B0F70FF", "#000004FF"],
  "viridisB" => ["#FCFFA4FF", "#FCA50AFF", "#DD513AFF", "#932667FF", "#420A68FF", "#000004FF"],
  "viridisC" => ["#F0F921FF", "#FCA636FF", "#E16462FF", "#B12A90FF", "#6A00A8FF", "#0D0887FF"],
  "viridisD" => ["#FDE725FF", "#7AD151FF", "#22A884FF", "#2A788EFF", "#414487FF", "#440154FF"],
  "viridisE" => ["#FFEA46FF", "#CBBA69FF", "#958F78FF", "#666970FF", "#31446BFF", "#00204DFF"]
)

mutable struct BayesplotAesthetics
    scheme::Dict
end


function get_color(levels::Array{String,1})
    levels = [full_level_name(level) for level in levels]
    if !all([level ∈ scheme_level_names() for level in levels])
        throw(ArgumentError("All levels must be in scheme_level_names()"))
    end
    color_vals = color_scheme_get()
    return [color_vals[level] for level in levels]
end


function color_scheme_set(scheme::String="blue")
    if !haskey(master_color_list, scheme)
        throw(ArgumentError("Invalid color scheme name."))
    end
    bayesplot_aesthetics.scheme = master_color_list[scheme]
end

bayesplot_aesthetics = BayesplotAesthetics(Dict())
color_scheme_set()
