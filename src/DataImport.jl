# src/DataImport.jl
module DataImport

using CSV, DataFrames, Dates, Statistics
include("FredUtils.jl")
using .FredUtils

export compute_dp, compute_tbill, compute_excess_returns, build_predictors

"""
    compute_dp(msi_path) -> DataFrame

Compute 12-month rolling dividend-price ratio from CRSP MSI data.
Replicates R logic: accumulate monthly dividends with reinvestment over 12 months.

Returns DataFrame with columns: dateym, dp.
"""
function compute_dp(msi_path::String)
    msi = CSV.read(msi_path, DataFrame)
    dropmissing!(msi, [:vwretd, :vwretx])

    n = nrow(msi)
    dpvw = 100.0 .* (msi.vwretd .- msi.vwretx) ./ (1.0 .+ msi.vwretx)
    retd_retx = (1.0 .+ msi.vwretd) ./ (1.0 .+ msi.vwretx)

    dp = zeros(n)
    for i in 11:-1:0
        for t in (i+1):n
            dp[t] = dp[t] * retd_retx[t-i] + dpvw[t-i]
        end
    end
    dp ./= 100.0

    dates = Date.(msi.date)
    dateym = year.(dates) .* 100 .+ month.(dates)

    return DataFrame(dateym = dateym, dp = dp)
end

end # module
