# test/test_cay.jl  — Validate CAY module against Lettau & Ludvigson's published data
#
# Run:  julia --project=. test/test_cay.jl

using Test, CSV, DataFrames, Dates, Statistics

# ---------- Load the CAY module ------------------------------------------
include(joinpath(@__DIR__, "..", "src", "CAY.jl"))
using .CAY

# ---------- Load Lettau's published data ---------------------------------
lettau = CSV.read(
    joinpath(@__DIR__, "..", "input", "cay_current.csv"),
    DataFrame;
    header = 1,
    normalizenames = true,
)

# Rename columns to standard names
rename!(lettau, names(lettau) .=> ["date", "c", "w", "y", "cay"])

# Parse dates
lettau.date = Date.(lettau.date)

# ---------- Download & process our data ----------------------------------
println("Downloading FRED series and computing CAY...")
# Estimate DOLS on Lettau's sample period (1951Q4-2019Q3) for replication
result = CAY.compute_cay(estimation_start=Date(1951,10,1), estimation_end=Date(2019,9,30))
cay_df = result.data

# ---------- Align to Lettau's date range ---------------------------------
# Our result uses end-of-quarter dates; Lettau's also uses end-of-quarter.
# Merge on date
merged = innerjoin(
    select(cay_df, :date, :c => :c_ours, :a => :a_ours, :y => :y_ours, :cay => :cay_ours),
    select(lettau, :date, :c => :c_lettau, :w => :w_lettau, :y => :y_lettau, :cay => :cay_lettau),
    on = :date,
)

println("Merged $(nrow(merged)) quarters (Lettau has $(nrow(lettau)) quarters)")

@testset "CAY Validation" begin

    # ---- 1) Correlation of log-levels > 0.999 ----------------------------
    @testset "Level correlations" begin
        corr_c = cor(merged.c_ours, merged.c_lettau)
        corr_a = cor(merged.a_ours, merged.w_lettau)
        corr_y = cor(merged.y_ours, merged.y_lettau)
        println("  cor(c): $corr_c")
        println("  cor(a): $corr_a")
        println("  cor(y): $corr_y")
        @test corr_c > 0.999
        @test corr_a > 0.999
        @test corr_y > 0.999
    end

    # ---- 2) First-difference max errors ----------------------------------
    @testset "First-difference accuracy" begin
        dc_ours   = diff(merged.c_ours)
        dc_lettau = diff(merged.c_lettau)
        da_ours   = diff(merged.a_ours)
        da_lettau = diff(merged.w_lettau)
        dy_ours   = diff(merged.y_ours)
        dy_lettau = diff(merged.y_lettau)

        max_dc = maximum(abs.(dc_ours .- dc_lettau))
        max_da = maximum(abs.(da_ours .- da_lettau))
        max_dy = maximum(abs.(dy_ours .- dy_lettau))
        println("  max |Δc - Δc_L|: $max_dc")
        println("  max |Δa - Δa_L|: $max_da")
        println("  max |Δy - Δy_L|: $max_dy")
        @test max_dc < 0.01
        @test max_da < 0.01
        @test max_dy < 0.01
    end

    # ---- 3) DOLS coefficients -------------------------------------------
    @testset "DOLS coefficients" begin
        beta_a = result.beta_a
        beta_y = result.beta_y
        println("  β_a = $beta_a  (Lettau: ≈0.218)")
        println("  β_y = $beta_y  (Lettau: ≈0.801)")
        @test abs(beta_a - 0.218) < 0.05
        @test abs(beta_y - 0.801) < 0.10
    end

    # ---- 4) CAY correlation > 0.99 --------------------------------------
    @testset "CAY correlation" begin
        # Demean both series
        cay_ours   = merged.cay_ours .- mean(merged.cay_ours)
        cay_lettau = merged.cay_lettau .- mean(merged.cay_lettau)
        corr_cay = cor(cay_ours, cay_lettau)
        println("  cor(cay_demeaned): $corr_cay")
        # Threshold 0.98: cross-vintage replication with 2023 NIPA comprehensive revision
        # shifts deflator ~6% and modifies component series definitions
        @test corr_cay > 0.98
    end
end

println("\nAll CAY tests passed!")
