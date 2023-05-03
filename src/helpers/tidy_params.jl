using DataFrames, DataFramesMeta

function param_range(prefix, range, vars=nothing)
    if vars !== nothing && !isa(vars, Vector{String})
        throw(ArgumentError("vars must be nothing or a vector of strings"))
    end
    nms = [string(prefix, "[", r, "]") for r in range]
    param_matches = [findfirst(==(nm), vars) for nm in nms]
    filter(!isnothing, param_matches)
end

function param_glue(pattern, args::NamedTuple, vars=nothing)
    if vars !== nothing && !isa(vars, Vector{String})
        throw(ArgumentError("vars must be nothing or a vector of strings"))
    end
    dots = Iterators.product((args[i] for i in keys(args))...)
    nms = [replace(pattern, r"\{(\w+)\}", s -> getindex.(args, s[1])) for args in dots]
    param_matches = [findfirst(==(nm), vars) for nm in nms]
    filter(!isnothing, param_matches)
end

function tidyselect_parameters(complete_pars::Vector{String}, pars_list)
    selected = complete_pars[[reduce(vcat, [f(complete_pars) for f in pars_list])...]]
    if isempty(selected)
        throw(ArgumentError("No parameters were found matching those names"))
    end
    selected
end
