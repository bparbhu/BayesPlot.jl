using DataFrames, DataFramesMeta, Gadfly
include("ppc_plots/ppc_helpers.jl")
include("helpers/bayesplot_helpers")
include("helpers/bayesplot_gadfly_themes")
include("helpers/gadfly_helper")


function ppd_data(ypred, group=nothing)
    ypred = validate_predictions(ypred)
    if group !== nothing
        group = validate_group(group, n_obs=ncol(ypred))
    end
    return ppd_data(predictions=ypred, y=nothing, group=group)
end


function ppd_dens_overlay(ypred;
                          size=0.25,
                          alpha=0.7,
                          trim=false,
                          bw="nrd0",
                          adjust=1,
                          kernel="gaussian",
                          n_dens=1024)

    data = ppd_data(ypred)

    # Note: You will need to define the following custom functions in Julia:
    # overlay_ppd_densities, scale_color_ppd, get_color, bayesplot_theme_get, 
    # dont_expand_axes, yaxis_title, xaxis_title, yaxis_text, yaxis_ticks, and legend_none

    plot(data,
        x=:value,
        layer(overlay_ppd_densities(group=:rep_id, color="ypred",
                                     linewidth=size, alpha=alpha,
                                     trim=trim, bw=bw, adjust=adjust,
                                     kernel=kernel, n=n_dens)),
        scale_color_ppd(values=get_color("m"),
                        guide=Guide.legend(override_aes=[size=2*size, alpha=1])),
        bayesplot_theme_get(),
        dont_expand_axes(),
        yaxis_title(false),
        xaxis_title(false),
        yaxis_text(false),
        yaxis_ticks(false),
        legend_none()
    )
end


function ppd_ecdf_overlay(ypred;
                          discrete=false,
                          pad=true,
                          size=0.25,
                          alpha=0.7)

    data = ppd_data(ypred)

    # Note: You will need to define the following custom functions in Julia:
    # hline_at, stat_ecdf, scale_color_ppd, get_color, bayesplot_theme_get, 
    # yaxis_title, xaxis_title, and legend_none

    plot(data,
        x=:value,
        layer(hline_at([0, 0.5, 1],
                       linewidth=[0.2, 0.1, 0.2],
                       linetype=2,
                       color=get_color("dh"))),
        stat_ecdf(group=:rep_id,
                  color="ypred",
                  geom=discrete ? "step" : "line",
                  linewidth=size,
                  alpha=alpha,
                  pad=pad),
        scale_color_ppd(values=get_color("m"),
                        guide=Guide.legend(override_aes=[linewidth=2*size, alpha=1])),
        Scale.y_continuous(breaks=[0, 0.5, 1]),
        bayesplot_theme_get(),
        yaxis_title(false),
        xaxis_title(false),
        legend_none()
    )
end

