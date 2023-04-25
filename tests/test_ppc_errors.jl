using Test
using Gadfly


@testset "PPC: predictive errors" begin
    @testset "ppc_error_hist and ppc_error_scatter return Gadfly.Plot object" begin
        @test isa(ppc_error_hist(y, yrep[1:5, :], binwidth = 0.1), Gadfly.Plot)
        @test isa(ppc_error_scatter(y, yrep[1:5, :]), Gadfly.Plot)

        @test isa(ppc_error_hist(y, yrep[1, :], binwidth = 0.1), Gadfly.Plot)
        @test isa(ppc_error_scatter(y, yrep[1, :]), Gadfly.Plot)

        @test isa(ppc_error_hist(y2, yrep2, binwidth = 0.1), Gadfly.Plot)
        @test isa(ppc_error_scatter(y2, yrep2), Gadfly.Plot)
    end

    @testset "ppc_error_hist_grouped returns Gadfly.Plot object" begin
        @test isa(ppc_error_hist_grouped(y, yrep[1:5, :], group, binwidth = 0.1), Gadfly.Plot)
        @test isa(ppc_error_hist_grouped(y, yrep[1, :], group, freq = false, binwidth = 1), Gadfly.Plot)
    end

    @testset "ppc_error_scatter_avg returns Gadfly.Plot object" begin
        @test isa(ppc_error_scatter_avg(y, yrep), Gadfly.Plot)
        @test isa(ppc_error_scatter_avg(y, yrep[1:5, :]), Gadfly.Plot)
    end

end

function bin_errors(y_obs, y_rep, bins=30)
    err <- y_obs .- y_rep
    se2 <- (err .- mean(err, dims=1)).^2
    n <- size(y_rep, 1)
    Ey <- mean(y_rep, dims=1)
    
    binned <- StatsBase.cut(Ey, bins=bins)
    err_bar <- DataFrames.by(binned, :Ey, :Ey => (x -> mean(x.err)) => :err_bar)
    ey_bar <- DataFrames.by(binned, :Ey, :Ey => (x -> mean(x.Ey)) => :ey_bar)
    se2_bar <- DataFrames.by(binned, :Ey, :Ey => (x -> sum(x.se2) / n) => :se2)
    
    return DataFrame(ey_bar = ey_bar.ey_bar, err_bar = err_bar.err_bar, se2 = se2_bar.se2, bin = 1:length(ey_bar.ey_bar))
end

function expect_gadfly(plot)
    @test isa(plot, Gadfly.Plot)
end
