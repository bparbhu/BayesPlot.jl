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
