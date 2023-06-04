# Function to check if a package is available with optional version checking
function suggested_package(pkg::String, min_version::Union{Nothing, VersionNumber}=nothing)
    if !haskey(Pkg.installed(), pkg)
        error("Please install the $pkg package to use this function.")
    end
    if min_version !== nothing && Pkg.installed()[pkg] < min_version
        error("Version >= $min_version of the $pkg package is required to use this function.")
    end
end

# If x is not nothing, return x, otherwise return y
@inline (x::Union{Nothing, T} || y::T) where {T} = isnothing(x) ? y : x

# Function to check if arguments were ignored
function check_ignored_arguments(kwargs::Base.Iterators.Pairs; ok_args=String[])
    nms = keys(kwargs)
    unrecognized = setdiff(nms, ok_args)
    if length(unrecognized) > 0
        @warn "The following arguments were unrecognized and ignored:" unrecognized
    end
end
