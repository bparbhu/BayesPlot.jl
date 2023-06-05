using ReferenceTests
using Gadfly
using BayesPlot
using Test

include("data_for_ppc_tests.jl")

function isgadfly(obj)
    return isa(obj, Gadfly.Plot)
end

@testset "PPC: distributions" begin
    @testset "ppc_dens_overlay returns a Gadfly object" begin
        y, yrep = data_for_ppc_tests()
        @test isgadfly(ppc_dens_overlay(y, yrep))
        @test isgadfly(ppc_dens_overlay(y2, yrep2, size = 0.5, alpha = 0.2))

        # ppd versions
        @test isgadfly(ppd_dens_overlay(yrep))
        @test isgadfly(ppd_dens_overlay(yrep2, size = 0.5, alpha = 0.2))
    end

    @testset "ppc_ecdf_overlay returns a Gadfly object" begin
        y, yrep = data_for_ppc_tests()
        @test isgadfly(ppc_ecdf_overlay(y, yrep))
        @test isgadfly(ppc_ecdf_overlay(y2, yrep2, size = 0.5, alpha = 0.2))

        # ppd versions
        @test isgadfly(ppd_ecdf_overlay(yrep))
        @test isgadfly(ppd_ecdf_overlay(yrep2, size = 0.5, alpha = 0.2))
    end

    @testset "ppc_stat_grouped returns a Gadfly object" begin
        y, yrep = data_for_ppc_tests()
        @test isgadfly(ppc_stat_grouped(y, yrep))
        @test isgadfly(ppc_stat_grouped(y2, yrep2, stat = :mean, size = 0.5, alpha = 0.2))

        # ppd versions
        @test isgadfly(ppd_stat_grouped(yrep))
        @test isgadfly(ppd_stat_grouped(yrep2, stat = :mean, size = 0.5, alpha = 0.2))
    end

    @testset "ppc_stat_freqpoly returns a Gadfly object" begin
        y, yrep = data_for_ppc_tests()
        @test isgadfly(ppc_stat_freqpoly(y, yrep))
        @test isgadfly(ppc_stat_freqpoly(y2, yrep2, nbins = 15, size = 0.5, alpha = 0.2))

        # ppd versions
        @test isgadfly(ppd_stat_freqpoly(yrep))
        @test isgadfly(ppd_stat_freqpoly(yrep2, nbins = 15, size = 0.5, alpha = 0.2))
    end


function create_reference_images()
    # Create reference images for each test case
    # This should be run only once to generate the initial reference images
    x = randn(100, 4)
    y = randn(100)
    group = rand(1:2, 100)

    # ppc_dens_overlay
    plot1 = ppc_dens_overlay(x, y)
    save("test/ref_images/ppc_dens_overlay_ref.png", plot1)

    # ppc_ecdf_overlay
    plot2 = ppc_ecdf_overlay(x, y)
    save("test/ref_images/ppc_ecdf_overlay_ref.png", plot2)

    # ppc_stat_grouped
    plot3 = ppc_stat_grouped(x, y, group)
    save("test/ref_images/ppc_stat_grouped_ref.png", plot3)

    # ppc_stat_freqpoly
    plot4 = ppc_stat_freqpoly(x, y)
    save("test/ref_images/ppc_stat_freqpoly_ref.png", plot4)

    # Repeat the process for the ppd_ versions of the functions
end

@testset "BayesPlot Tests" begin
    x = randn(100, 4)
    y = randn(100)
    group = rand(1:2, 100)

    # Test if functions return Gadfly objects
    @test isgadfly(ppc_dens_overlay(x, y))
    @test isgadfly(ppc_ecdf_overlay(x, y))
    @test isgadfly(ppc_stat_grouped(x, y, group))
    @test isgadfly(ppc_stat_freqpoly(x, y))

    # Test if generated plots match the reference images
    @test test_image("test/ref_images/ppc_dens_overlay_ref.png", ppc_dens_overlay(x, y))
    @test test_image("test/ref_images/ppc_ecdf_overlay_ref.png", ppc_ecdf_overlay(x, y))
    @test test_image("test/ref_images/ppc_stat_grouped_ref.png", ppc_stat_grouped(x, y, group))
    @test test_image("test/ref_images/ppc_stat_freqpoly_ref.png", ppc_stat_freqpoly(x, y))

    # Repeat the tests for the ppd_ versions of the functions
end