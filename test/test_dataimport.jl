# test/test_dataimport.jl
using Test, CSV, DataFrames, Dates, Statistics

# Load R reference
ref = CSV.read("output/predict.csv", DataFrame)
println("Reference predict.csv: $(nrow(ref)) obs, dateym $(ref.dateym[1]) to $(ref.dateym[end])")

include(joinpath(@__DIR__, "..", "src", "DataImport.jl"))
using .DataImport

# --- Test D/P ratio ---
dp_df = DataImport.compute_dp("output/msi.csv")
# Merge on dateym
comp = innerjoin(
    select(ref, :dateym, :dp => :dp_ref),
    dp_df,
    on=:dateym
)
maxerr = maximum(abs.(comp.dp .- comp.dp_ref))
println("D/P ratio max absolute error: $maxerr")
@test maxerr < 1e-10
println("D/P ratio matches R output")

# --- Test T-bill ---
tbill_df = DataImport.compute_tbill()
comp_rf = innerjoin(
    select(ref, :dateym, :rf => :rf_ref),
    tbill_df,
    on=:dateym
)
maxerr_rf = maximum(abs.(comp_rf.rf .- comp_rf.rf_ref))
println("T-bill max absolute error: $maxerr_rf")
@test maxerr_rf < 1e-6
println("✓ T-bill matches R output")

# --- Test future excess returns ---
rmrf_df = DataImport.compute_excess_returns("output/msi.csv", tbill_df)
comp_rmrf = innerjoin(
    select(ref, :dateym, :rmrf_y3 => :rmrf_ref),
    rmrf_df,
    on=:dateym
)
dropmissing!(comp_rmrf)
maxerr_rmrf = maximum(abs.(comp_rmrf.rmrf_y3 .- comp_rmrf.rmrf_ref))
println("Excess return max absolute error: $maxerr_rmrf")
@test maxerr_rmrf < 1e-10
println("✓ Future excess returns match R output")
