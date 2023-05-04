using Test, ReferenceTests
using DataFrames, DataFramesMeta

# melt_predictions, melt_and_stack, is_whole_number, all_counts,
# adjust_gamma, get_interpolation_values, ecdf_intervals

y = example_y_data()
yrep = example_yrep_draws()[1:25, :]

@testset "melt_predictions returns correct structure" begin
    for yrep in (yrep, yrep2, Ey)
        x = melt_predictions(yrep)
        @test size(x, 2) == 5
        @test size(x, 1) == length(y) * size(yrep, 1)

        rep_nums = repeat(1:size(yrep, 1), inner = length(y))
        obs_nums = repeat(1:length(y), outer = size(yrep, 1))

        @test names(x) == ["y_id", "y_name", "rep_id", "rep_label", "value"]
        @test x[!, "y_id"] == obs_nums
        @test x[!, "rep_id"] == rep_nums

        @test typeof(x) <: AbstractDataFrame
        @test typeof(x[!, "rep_label"]) <: CategoricalArray
        @test typeof(x[!, "rep_id"]) <: Vector{Int}
        @test typeof(x[!, "y_id"]) <: Vector{Int}
        @test typeof(x[!, "value"]) <: Vector{Float64}
    end
end

@testset "melt_and_stack returns correct structure" begin
    molten_yrep = melt_predictions(yrep)
    d = melt_and_stack(y, yrep)
    @test typeof(d) <: AbstractDataFrame
    @test size(d, 1) == size(molten_yrep, 1) + length(y)

    sorted_names = sort(vcat(names(molten_yrep), ["is_y", "is_y_label"]))
    @test sort(names(d)) == sorted_names
end

# Tests for is_whole_number and all_counts are omitted because
# these functions were not provided in previous questions.

@testset "adjust_gamma works with different adjustment methods" begin
    Random.seed!(8420)

    adj1 = adjust_gamma(N=100, K=100, L=1, prob=0.99)
    adj2 = adjust_gamma(N=100, K=100, L=1, prob=0.99, interpolate_adj=true)
    @test adj1 ≈ adj2 atol = 1e-3

    adj3 = adjust_gamma(N=100, K=100, L=4, prob=0.99, M=1000)
    adj4 = adjust_gamma(N=100, K=100, L=4, prob=0.99, interpolate_adj=true)
    @test adj3 ≈ adj4 atol = 1e-3

    Random.seed!()
end
