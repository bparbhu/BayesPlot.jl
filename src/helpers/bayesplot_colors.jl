using Gadfly

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
