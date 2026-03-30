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

"""
    compute_tbill(; observation_end) -> DataFrame

Download 3-month T-bill from FRED (TB3MS). Returns DataFrame with dateym, rf.
"""
function compute_tbill(; observation_end::Date = Date(2026,12,31))
    df = fred_observations("TB3MS"; end_date=observation_end)
    dropmissing!(df)
    dateym = year.(df.date) .* 100 .+ month.(df.date)
    rf = df.value ./ 100.0
    return DataFrame(dateym = dateym, rf = rf)
end

"""
    compute_excess_returns(msi_path, tbill_df) -> DataFrame

Compute 3-year geometric average future excess returns.
Replicates R logic from import_predictors.R lines 100-114.

The R code does:
1. lead1_retm = shift(retm, 1, type="lead")  -- next month's return
2. retm_y = exp(roll_sum(log(1+lead1_retm), n=12, align="left")) - 1  -- 12-month forward return
3. rf_y = geometric average of quarterly T-bill rates (current + 3,6,9 month leads)
4. rmrf_y3 = 3-year geometric average excess return
"""
function compute_excess_returns(msi_path::String, tbill_df::DataFrame)
    msi = CSV.read(msi_path, DataFrame)
    dropmissing!(msi, [:vwretd])
    dates = Date.(msi.date)
    dateym = year.(dates) .* 100 .+ month.(dates)

    df = DataFrame(dateym = dateym, retm = msi.vwretd)
    df = innerjoin(df, tbill_df, on=:dateym)

    n = nrow(df)
    retm = df.retm
    rf = df.rf

    # 12-month forward market return: lead by 1, then rolling 12-month sum of log returns
    retm_y = Vector{Union{Float64,Missing}}(missing, n)
    for t in 1:(n-12)
        retm_y[t] = exp(sum(log.(1.0 .+ retm[(t+1):(t+12)]))) - 1.0
    end

    # Annual risk-free: geometric average of quarterly T-bill
    rf_y = Vector{Union{Float64,Missing}}(missing, n)
    for t in 1:(n-9)
        rf_y[t] = (1+rf[t])^0.25 * (1+rf[t+3])^0.25 * (1+rf[t+6])^0.25 * (1+rf[t+9])^0.25 - 1.0
    end

    # 3-year geometric average excess return
    rmrf_y3 = Vector{Union{Float64,Missing}}(missing, n)
    for t in 1:(n-24)
        if !ismissing(retm_y[t]) && !ismissing(retm_y[t+12]) && !ismissing(retm_y[t+24]) &&
           !ismissing(rf_y[t])   && !ismissing(rf_y[t+12])   && !ismissing(rf_y[t+24])
            rmrf_y3[t] = (
                ((1+retm_y[t]) * (1+retm_y[t+12]) * (1+retm_y[t+24]))^(1/3) -
                (((1+rf_y[t])  * (1+rf_y[t+12])   * (1+rf_y[t+24]))^(1/3) - 1) - 1
            )
        end
    end

    return DataFrame(dateym = df.dateym, rmrf_y3 = rmrf_y3)
end

"""
    build_predictors(msi_path, cay_path) -> DataFrame

Full pipeline: compute D/P, download T-bill, compute excess returns,
load CAY, merge all. Returns DataFrame with: dateym, dp, rf, rmrf_y3, cay.
"""
function build_predictors(msi_path::String, cay_path::String)
    dp_df    = compute_dp(msi_path)
    tbill_df = compute_tbill()
    rmrf_df  = compute_excess_returns(msi_path, tbill_df)

    # Load CAY (either Lettau's or our computed version)
    cay_raw = CSV.read(cay_path, DataFrame; header=1)
    rename!(cay_raw, Symbol.(["date", "c", "w", "y", "cay"]))
    cay_raw.date = Date.(cay_raw.date)
    cay_df = DataFrame(
        dateym = year.(cay_raw.date) .* 100 .+ month.(cay_raw.date),
        cay = cay_raw.cay,
    )

    # Merge
    predict = innerjoin(dp_df, tbill_df, on=:dateym)
    predict = innerjoin(predict, rmrf_df, on=:dateym)
    predict = innerjoin(predict, cay_df, on=:dateym)
    dropmissing!(predict)

    return predict
end

# When run as script
if abspath(PROGRAM_FILE) == @__FILE__
    mkpath("tmp")
    predict = build_predictors("output/msi.csv", "input/cay_computed.csv")
    CSV.write("tmp/predict.csv", predict)
    println("Wrote tmp/predict.csv: $(nrow(predict)) rows")
end

end # module
