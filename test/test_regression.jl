# test/test_regression.jl
using Test, CSV, DataFrames, Statistics

# R reference coefficients from readme.md (full sample, 264 obs)
ref_coefs = Dict(
    :dp  => 3.370,
    :cay => 1.814,
    :rf  => -1.246,
    :constant => 0.011,
)
ref_r2 = 0.344
ref_nobs = 264

include(joinpath(@__DIR__, "..", "src", "RiskPremium.jl"))
using .RiskPremium

# Use the R reference predict.csv directly (already validated in test_dataimport.jl)
predict = CSV.read("output/predict.csv", DataFrame)
result = RiskPremium.run_regression(predict)

println("Coefficients:")
println("  dp:    $(round(result.coefs[:dp], digits=3)) (ref: $(ref_coefs[:dp]))")
println("  cay:   $(round(result.coefs[:cay], digits=3)) (ref: $(ref_coefs[:cay]))")
println("  rf:    $(round(result.coefs[:rf], digits=3)) (ref: $(ref_coefs[:rf]))")
println("  const: $(round(result.coefs[:constant], digits=3)) (ref: $(ref_coefs[:constant]))")
println("R²: $(round(result.r2, digits=3)) (ref: $ref_r2)")
println("N:  $(result.nobs) (ref: $ref_nobs)")

@testset "Regression validation" begin
    for (k, v) in ref_coefs
        err = abs(result.coefs[k] - v)
        println("  $k error: $err")
        @test err < 0.01
    end
    @test abs(result.r2 - ref_r2) < 0.005
    @test result.nobs == ref_nobs
end

println("✓ Regression coefficients match R output")
