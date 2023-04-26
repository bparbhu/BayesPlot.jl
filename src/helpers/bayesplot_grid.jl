using Gadfly, DataFrames, DataFramesMeta


function bayesplot_grid(plots::Vector{Plot} = Plot[];
                        xlim::Union{Tuple{Real,Real}, Nothing} = nothing,
                        ylim::Union{Tuple{Real,Real}, Nothing} = nothing,
                        titles::Vector{String} = String[],
                        subtitles::Vector{String} = String[],
                        legends::Bool = true,
                        save_gg_objects::Bool = true)

    if isempty(plots)
        error("No plots specified.")
    end

    if !isempty(titles)
        @assert length(titles) == length(plots) "Length of titles must match the number of plots."
        for (i, title) in enumerate(titles)
            push!(plots[i].mapping.title, title)
        end
    end

    if !isempty(subtitles)
        @assert length(subtitles) == length(plots) "Length of subtitles must match the number of plots."
        for (i, subtitle) in enumerate(subtitles)
            push!(plots[i].mapping.subtitle, subtitle)
        end
    end

    if !legends
        for plot in plots
            plot.mapping.legend=nothing
        end
    end

    if !isnothing(xlim)
        for plot in plots
            plot.mapping.xmin, plot.mapping.xmax = xlim
        end
    end

    if !isnothing(ylim)
        for plot in plots
            plot.mapping.ymin, plot.mapping.ymax = ylim
        end
    end

    gridstack(plots)
end


function display_bayesplot_grid(grid)
    display(grid)
end
