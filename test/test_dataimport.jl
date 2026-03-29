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
