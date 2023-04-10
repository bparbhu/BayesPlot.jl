using Gadfly, DataFrames, KernelDensity, Survival, DataFramesMeta, GadflyExtensions


function ppc_km_overlay(y, yrep, status_y, size=0.25, alpha=0.7)
    @assert isnumeric(status_y)
    @assert all(status_y .∈ Ref([0, 1]))

    data = ppc_data(y, yrep, group=status_y)

    data = @transform(data,
        group = ifelse(:is_y, parse.(Float64, string.(:group)), 1))

    sf_form = @formula(Surv(value, group) ~ rep_label)
    sf = survfit(sf_form, data)
    fsf = fortify(sf)

    fsf[!, :is_y_color] = categorical(replace.(string.(fsf[!, :strata]), r"\\[rep\\] \\(.*\$" => "rep", "^italic\\(y\\)" => "y"))
    fsf[!, :is_y_size] = ifelse.(fsf[!, :is_y_color] .== "yrep", size, 1)
    fsf[!, :is_y_alpha] = ifelse.(fsf[!, :is_y_color] .== "yrep", alpha, 1)

    fsf[!, :strata] = categorical(fsf[!, :strata], levels = reverse(levels(fsf[!, :strata])))

    p = plot(fsf, x=:time, y=:surv, color=:is_y_color, group=:strata, size=:is_y_size, alpha=:is_y_alpha, Geom.step,
        Guide.xlabel(y_label()), Guide.ylabel(""),
        Guide.title(""),
        Theme(line_width=[0.1], line_style=[:dot], line_color=["gray"]),
        Coord.cartesian(ymin=0, ymax=1, ymin_fixed=true, ymax_fixed=true))
    return p
end


function ppc_km_overlay_grouped(y, yrep, group, status_y; size=0.25, alpha=0.7)
    p_overlay = ppc_km_overlay(y, yrep, status_y, size=size, alpha=alpha)

    p = plot(p_overlay, Guide.xlabel(""),
        Guide.title(""),
        facet=:group)

    return p
end

