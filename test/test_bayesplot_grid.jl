using Test, ReferenceTests
using Gadfly, DataFrames, DataFramesMeta

# example_y_data, example_yrep_draws, ppc_stat, ppc_scatter_avg, as_bayesplot_grid

y = example_y_data()
yrep = example_yrep_draws()[1:25, :]
gr = gridExtra.arrangeGrob(ppc_stat(y, yrep, binwidth=1))
p1 = ppc_scatter_avg(y, yrep)
p2 = ppc_stat(y, yrep, binwidth=1)

@testset "as_bayesplot_grid works" begin
    @test isa(as_bayesplot_grid(gr), BayesplotGrid)
    @test isa(as_bayesplot_grid(gr), GTable)
end

@testset "bayesplot_grid throws correct errors" begin
    @test_throws ErrorException bayesplot_grid(xlim=2)
    @test_throws ErrorException bayesplot_grid(gr, plots=[p1, p2])
    @test_throws ErrorException bayesplot_grid(plots=gr)
    @test_throws ErrorException bayesplot_grid(gr)
    @test_throws ErrorException bayesplot_grid(p1, p2, titles=["plot1"])
    @test_throws ErrorException bayesplot_grid(p1, p2, subtitles=["plot1"])
end

@testset "bayesplot_grid works" begin
    a = @test_warn "is already present" bayesplot_grid(p1, p2, xlim=(-200, 200), ylim=(0, 200))
    b = bayesplot_grid(plots=[p1, p2],
                       titles=["plot1", "plot2"],
                       subtitles=["plot1_sub", "plot2_sub"],
                       legends=false)

    @test isa(a, BayesplotGrid)
    @test isa(b, BayesplotGrid)
    @test length(a.grobs) == 2
    @test length(b.grobs) == 2
end
