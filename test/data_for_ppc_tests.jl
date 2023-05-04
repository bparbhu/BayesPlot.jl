using Random, Distributions, DataFrames

Random.seed!(8420)
y = rand(Normal(), 100)
yrep = rand(Normal(), 2500) |> reshape(_, 100)
group = repeat(["A", "B", "C", "D"], inner=25)
status_y = repeat(0:1, outer=div(length(y), 2))

y2 = rand(Poisson(1), 30)
yrep2 = rand(Poisson(1), 30) |> reshape(_, 30)
group2 = fill(1, 30)
status_y2 = repeat(0:1, outer=div(length(y2), 2))


# for vdiffr visual tests
Random.seed!(11172017)
vdiff_y = rand(Normal(), 100)
vdiff_yrep = rand(Normal(), 2500) |> reshape(_, 100)
vdiff_group = repeat(["A", "B", "C", "D"], inner=25)
vdiff_status_y = repeat(0:1, outer=div(length(vdiff_y), 2))

vdiff_y2 = rand(Poisson(1), 30)
vdiff_yrep2 = rand(Poisson(1), 30 * 10) |> reshape(_, 30)
vdiff_group2 = repeat([1, 2], outer=div(30, 2))
vdiff_status_y2 = repeat(0:1, outer=div(length(vdiff_y2), 2))

vdiff_loo_y = rand(Normal(30, 5), 100)
vdiff_loo_yrep = rand(Normal(30, 5), 100 * 400) |> reshape(_, 400)
vdiff_loo_lw = copy(vdiff_loo_yrep)
vdiff_loo_lw .= rand(Normal(-8, 2), 100 * 400)

Random.seed!(nothing)
