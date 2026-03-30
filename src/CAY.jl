# src/CAY.jl
module CAY

using DataFrames, Dates, Statistics, LinearAlgebra, CSV
include("FredUtils.jl")
using .FredUtils

export compute_cay

# FRED series IDs for CAY components
const SERIES = Dict(
    :consumption     => "PCEC",              # Total PCE, Q, Bil $, SAAR
    :net_worth       => "TNWBSHNO",          # HH Net Worth, Q, Mil $
    :wages           => "WASCUR",            # Wages & Salary Accruals, Q, Bil $
    :transfers       => "A577RC1Q027SBEA",   # Personal Current Transfer Receipts, Q
    :other_labor     => "B040RC1Q027SBEA",   # Employer Pension/Insurance Contrib, Q
    :social_ins      => "A061RC1Q027SBEA",   # Contributions for Govt Social Ins, Q
    :personal_income => "PINCOME",           # Personal Income, Q, Bil $
    :personal_taxes  => "W055RC1Q027SBEA",   # Personal Current Taxes, Q
    :deflator        => "PCECTPI",           # PCE Price Index, Q, Index
    :population      => "B230RC0Q173SBEA",   # BEA Midperiod Pop, Q, Thousands
)

"""
    download_macro_data() -> DataFrame

Download all macro components from FRED and return a quarterly DataFrame.
"""
function download_macro_data()
    println("Checking FRED series metadata:")
    for (name, sid) in sort(collect(SERIES), by=first)
        info = fred_series_info(sid)
        println("  $name ($sid): $(info.frequency), $(info.units), $(info.observation_start)–$(info.observation_end)")
    end

    raw = Dict{Symbol, DataFrame}()
    for (name, sid) in SERIES
        raw[name] = fred_observations(sid)
        println("Downloaded $name: $(nrow(raw[name])) obs")
    end

    # Consumption
    df = rename(raw[:consumption], :value => :consumption)

    # Net worth: Millions -> Billions
    nw = copy(raw[:net_worth])
    nw.value ./= 1000.0
    rename!(nw, :value => :net_worth)
    df = innerjoin(df, nw, on=:date)

    # Labor income construction
    wages = rename(raw[:wages], :value => :wages)
    trans = rename(raw[:transfers], :value => :transfers)
    other = rename(raw[:other_labor], :value => :other_labor)
    si    = rename(raw[:social_ins], :value => :social_ins)
    pi    = rename(raw[:personal_income], :value => :personal_income)
    tax   = rename(raw[:personal_taxes], :value => :personal_taxes)

    li = innerjoin(wages, trans, other, si, pi, tax, on=:date)
    li.li_pretax = li.wages .+ li.transfers .+ li.other_labor .- li.social_ins
    li.labor_share = li.li_pretax ./ li.personal_income
    li.labor_income = li.li_pretax .- li.labor_share .* li.personal_taxes
    df = innerjoin(df, select(li, :date, :labor_income), on=:date)

    # Deflator and population
    defl = rename(raw[:deflator], :value => :deflator)
    pop  = rename(raw[:population], :value => :population)
    df = innerjoin(df, defl, pop, on=:date)

    dropmissing!(df)
    return df
end

"""
    process_components(df::DataFrame) -> DataFrame

Convert nominal aggregates to log real per-capita: c, a, y.
"""
function process_components(df::DataFrame)
    # Convert start-of-quarter dates to end-of-quarter (to match Lettau convention)
    out = DataFrame(date = Dates.lastdayofmonth.(df.date .+ Dates.Month(2)))
    # Real per-capita in dollars per person:
    # consumption/income in billions, population in thousands
    # => multiply by 1e9 / 1e3 = 1e6 to get dollars per person
    # deflator is index with base=100, so divide by (deflator/100)
    out.c = log.(df.consumption  ./ df.deflator .* 100 ./ df.population .* 1e6)
    out.a = log.(df.net_worth    ./ df.deflator .* 100 ./ df.population .* 1e6)
    out.y = log.(df.labor_income ./ df.deflator .* 100 ./ df.population .* 1e6)
    return out
end

"""
    estimate_dols(c, a, y; K=8) -> NamedTuple

Stock-Watson Dynamic OLS for cointegrating regression:
  c_t = α + β_a*a_t + β_y*y_t + Σ_{j=-K}^{K} γ_j*Δa_{t+j} + Σ_{j=-K}^{K} δ_j*Δy_{t+j} + ε_t
"""
function estimate_dols(c::Vector{Float64}, a::Vector{Float64}, y::Vector{Float64}; K::Int=8)
    T = length(c)
    @assert length(a) == T && length(y) == T

    # Valid range: need Δx[t+j] for j in -K:K, where Δx[t] = x[t]-x[t-1]
    # Δx exists for t=2:T, so t+j ∈ [2,T] => t ∈ [K+2, T-K]
    valid = (K+2):(T-K)
    n = length(valid)

    ncols = 1 + 2 + 2*(2K+1)  # intercept + a,y + leads/lags of Δa,Δy
    X = zeros(n, ncols)
    Y = c[valid]

    X[:, 1] .= 1.0
    X[:, 2] = a[valid]
    X[:, 3] = y[valid]

    col = 4
    for j in -K:K
        X[:, col] = [a[t+j] - a[t+j-1] for t in valid]
        col += 1
    end
    for j in -K:K
        X[:, col] = [y[t+j] - y[t+j-1] for t in valid]
        col += 1
    end

    β = X \ Y
    α   = β[1]
    β_a = β[2]
    β_y = β[3]

    # Compute cay for full sample
    cay = c .- α .- β_a .* a .- β_y .* y

    println("DOLS coefficients: α=$(round(α, digits=4)), β_a=$(round(β_a, digits=4)), β_y=$(round(β_y, digits=4))")
    println("  (Lettau reference: α≈-0.441, β_a≈0.218, β_y≈0.801)")

    return (; α, β_a, β_y, cay, valid)
end

"""
    compute_cay(; K=8, estimation_end=nothing) -> NamedTuple

Full pipeline: download data, process, estimate DOLS.
If `estimation_end` is provided, DOLS is estimated only on data up to that date,
but cay is computed for the full sample using the estimated coefficients.
Returns (; data::DataFrame, beta_a, beta_y, alpha) where data has columns
date, c, a, y, cay.
"""
function compute_cay(; K::Int=8,
        estimation_start::Union{Date,Nothing}=nothing,
        estimation_end::Union{Date,Nothing}=nothing)
    raw = download_macro_data()
    df = process_components(raw)
    dropmissing!(df)

    # Restrict estimation sample if requested
    est_mask = trues(nrow(df))
    if estimation_start !== nothing
        est_mask .&= df.date .>= estimation_start
    end
    if estimation_end !== nothing
        est_mask .&= df.date .<= estimation_end
    end

    if any(.!est_mask)
        est_idx = findall(est_mask)
        println("DOLS estimation sample: $(df.date[est_idx[1]]) to $(df.date[est_idx[end]]) ($(length(est_idx)) obs)")
        result = estimate_dols(df.c[est_idx], df.a[est_idx], df.y[est_idx]; K)
        # Recompute cay for full sample using estimated coefficients
        cay_full = df.c .- result.α .- result.β_a .* df.a .- result.β_y .* df.y
    else
        result = estimate_dols(df.c, df.a, df.y; K)
        cay_full = result.cay
    end

    data = DataFrame(
        date = df.date,
        c    = df.c,
        a    = df.a,
        y    = df.y,
        cay  = cay_full,
    )
    return (; data, beta_a=result.β_a, beta_y=result.β_y, alpha=result.α)
end

# When run as script
if abspath(PROGRAM_FILE) == @__FILE__
    # Estimate DOLS on pre-COVID sample (1951Q4–2019Q3) to avoid distortion from
    # the pandemic period (large swings in transfers, consumption, and asset values).
    # The estimated coefficients are then applied to the full sample to extend cay.
    res = compute_cay(estimation_start=Date(1951,10,1), estimation_end=Date(2019,9,30))
    # Write with column names matching Lettau's format: date,c,w,y,cay
    out = rename(res.data, :a => :w)
    CSV.write("input/cay_computed.csv", out)
    println("Wrote input/cay_computed.csv: $(nrow(out)) rows, $(out.date[1]) to $(out.date[end])")
end

end # module
