module RiskPremium

using CSV, DataFrames, Dates, Statistics, LinearAlgebra
using Plots
pgfplotsx()

export run_regression, format_table, make_plot

"""
    newey_west_vcov(X, residuals; lag=12)

Newey-West HAC variance-covariance matrix with Bartlett kernel.
Matches R's sandwich::NeweyWest(model, lag=12, prewhite=FALSE).
"""
function newey_west_vcov(X::Matrix{Float64}, e::Vector{Float64}; lag::Int=12)
    n, k = size(X)
    XX_inv = inv(X'X)

    # Meat: S = Σ w(l) * [Γ(l) + Γ(l)'] with Bartlett weights
    S = zeros(k, k)
    for l in 0:lag
        w = 1.0 - l / (lag + 1)  # Bartlett kernel
        Γ = zeros(k, k)
        for t in (l+1):n
            Γ .+= e[t] * e[t-l] .* (X[t,:] * X[t-l,:]')
        end
        if l == 0
            S .+= w .* Γ
        else
            S .+= w .* (Γ .+ Γ')
        end
    end

    V = XX_inv * S * XX_inv
    return V
end

"""
    run_regression(predict; sample_filter=nothing) -> NamedTuple

Run OLS: rmrf_y3 ~ dp + cay + rf with Newey-West(12) standard errors.
Returns (coefs, se, r2, nobs, residuals, fitted).
"""
function run_regression(predict::DataFrame; sample_filter=nothing)
    df = isnothing(sample_filter) ? copy(predict) : filter(sample_filter, predict)

    y = Float64.(df.rmrf_y3)
    n = length(y)
    X = hcat(ones(n), Float64.(df.dp), Float64.(df.cay), Float64.(df.rf))
    varnames = [:constant, :dp, :cay, :rf]

    β = X \ y
    ŷ = X * β
    e = y .- ŷ

    ss_res = sum(e.^2)
    ss_tot = sum((y .- mean(y)).^2)
    r2 = 1.0 - ss_res / ss_tot

    V = newey_west_vcov(X, e; lag=12)
    se = sqrt.(diag(V))

    coefs = Dict(varnames .=> β)
    ses   = Dict(varnames .=> se)

    return (; coefs, se=ses, r2, nobs=n, residuals=e, fitted=ŷ, β, varnames)
end

"""
    format_table(result) -> String

Format regression output as text table (replaces stargazer).
"""
function format_table(result)
    lines = String[]
    push!(lines, "~~~R")
    push!(lines, "===========================================================")
    push!(lines, "                             Future Excess Returns         ")
    push!(lines, "-----------------------------------------------------------")

    labels = Dict(:dp => "D/P ratio", :cay => "cay", :rf => "T-bill (three-month)", :constant => "Constant")

    for var in [:dp, :cay, :rf, :constant]
        b = result.coefs[var]
        s = result.se[var]
        z = abs(b / s)
        p = 2.0 * (1.0 - _Φ(z))
        st = p < 0.01 ? "***" : p < 0.05 ? "**" : p < 0.10 ? "*" : ""
        push!(lines, "$(rpad(labels[var], 35))$(lpad(string(round(b, digits=3)) * st, 20))")
        push!(lines, "$(rpad("", 35))$(lpad("(" * string(round(s, digits=3)) * ")", 20))")
        push!(lines, "")
    end

    push!(lines, "$(rpad("Observations", 35))$(lpad(string(result.nobs), 20))")
    push!(lines, "$(rpad("R2", 35))$(lpad(string(round(result.r2, digits=3)), 20))")
    push!(lines, "-----------------------------------------------------------")
    push!(lines, "Notes:               ***Significant at the 1 percent level.")
    push!(lines, "                     **Significant at the 5 percent level. ")
    push!(lines, "                     *Significant at the 10 percent level. ")
    push!(lines, "~~~")
    return join(lines, "\n")
end

# Standard normal CDF
function _Φ(x)
    return 0.5 * (1.0 + erf(x / sqrt(2.0)))
end

"""
    make_plot(predict)

Plot expected vs realized excess returns. Uses Plots.jl with PGFPlotsX backend.
"""
function make_plot(predict::DataFrame)
    dates = Date.(
        div.(predict.dateym, 100),
        mod.(predict.dateym, 100),
        1
    )

    p = plot(dates, 100 .* predict.rmrf_y3;
        label  = "Realized",
        color  = :steelblue,
        alpha  = 0.75,
        lw     = 0.5,
        marker = (:circle, 2, 0.5, :steelblue),
        xlabel = "",
        ylabel = "Returns (percent)",
        legend = :topleft,
    )
    plot!(p, dates, 100 .* predict.exp_rmrf;
        label  = "Expected",
        color  = :indianred,
        alpha  = 0.75,
        lw     = 0.5,
        marker = (:circle, 2, 0.5, :indianred),
    )

    savefig(p, "output/predict.pdf")
    println("Wrote output/predict.pdf")
end

# When run as script
if abspath(PROGRAM_FILE) == @__FILE__
    predict = CSV.read("tmp/predict.csv", DataFrame)
    predict.year = div.(predict.dateym, 100)

    r1 = run_regression(predict; sample_filter = r -> r.year < 2011)
    println("In-sample (year < 2011):")
    println("  β_dp=$(round(r1.coefs[:dp], digits=3)), β_cay=$(round(r1.coefs[:cay], digits=3)), β_rf=$(round(r1.coefs[:rf], digits=3))")

    r2 = run_regression(predict)
    println("\nFull sample:")
    println("  β_dp=$(round(r2.coefs[:dp], digits=3)), β_cay=$(round(r2.coefs[:cay], digits=3)), β_rf=$(round(r2.coefs[:rf], digits=3))")

    predict.exp_rmrf = r2.fitted
    CSV.write("output/predict.csv", select(predict, :dateym, :dp, :rf, :rmrf_y3, :cay, :exp_rmrf))

    table = format_table(r2)
    mkpath("tmp")
    write("tmp/reg_update.txt", table)
    println("\nWrote output/predict.csv and tmp/reg_update.txt")

    make_plot(predict)
end

end # module
