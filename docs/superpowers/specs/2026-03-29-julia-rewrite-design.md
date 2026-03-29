# RiskPremium: Julia Rewrite + CAY Construction

## Goal

Rewrite the risk premium estimation pipeline from R to Julia and construct the CAY variable from raw FRED/Flow of Funds data, removing the dependency on Lettau's website. Validate each step against existing R output for bit-by-bit replication.

## Current State

The R pipeline has two scripts orchestrated by a Makefile:

- `src/import_predictors.R` — downloads TB3MS from FRED, reads CRSP MSI from SAS, constructs D/P ratio and 3-year future excess returns, merges with CAY from a pre-downloaded CSV
- `src/rp_measure.R` — runs predictive regression (OLS + Newey-West), produces predictions, table, and plot

Data coverage:
- `output/msi.csv`: 1925-12 to 2022-03 (CRSP monthly returns)
- `input/cay_current.csv`: 1952Q1 to 2019Q3 (Lettau's CAY, last updated)
- `output/predict.csv`: 1952-03 to 2017-12 (264 obs, limited by 3-year forward horizon)

CAY has not been updated since 2019Q3 and Lettau's website has migrated. The old download URLs are broken.

## Architecture

Three Julia source files called directly from Makefile targets. No wrapper script.

### `src/CAY.jl` — CAY construction from raw data

Downloads macro components from FRED and estimates the consumption-wealth ratio:

1. **Consumption (c):** PCND (nondurables) + PCESV (services) from NIPA
2. **Asset wealth (a):** Household net worth from Flow of Funds (Z.1 release)
3. **Labor income (y):** Wage and salary disbursements or compensation of employees
4. **Deflator:** PCECTPI (PCE price index)
5. **Population:** CNP16OV or B230RC0Q173SBEA

Processing:
- Deflate nominal series to real
- Convert to per-capita
- Take logs
- Estimate cointegrating vector via Stock-Watson DOLS (8 leads/lags of first-differenced regressors)
- CAY = residual from cointegrating regression

Validation target: replicate `input/cay_current.csv` on Lettau's sample (1951Q4-2019Q3) with coefficients close to `beta_a = 0.218, beta_y = 0.801`.

Output: `input/cay_computed.csv` (and once validated, replaces `input/cay_current.csv`)

### `src/DataImport.jl` — Predictor construction

1. **TB3MS:** Download 3-month T-bill from FRED API
2. **D/P ratio:** Read `output/msi.csv`, compute 12-month rolling reinvested dividend-price ratio (replicating the R logic in import_predictors.R lines 84-95)
3. **Future excess returns:** Compute 3-year geometric average excess returns from monthly CRSP returns minus T-bill (replicating R logic in lines 100-114)
4. **Merge:** Combine D/P, T-bill, future excess returns, and CAY by date

Output: `tmp/predict.csv`

Validation: each column matches R's `output/predict.csv` within floating-point tolerance.

### `src/RiskPremium.jl` — Predictive regression and output

1. **OLS regression:** `rmrf_y3 ~ dp + cay + rf`
   - In-sample: year < 2011
   - Full sample: all available data
2. **Newey-West standard errors** (lag = 12, no prewhitening)
3. **Output:** predictions to `output/predict.csv`, regression table to `tmp/reg_update.txt`, plot to `output/predict.png`

Validation: regression coefficients and R-squared match R output.

## Makefile Structure

```makefile
input/cay_computed.csv: src/CAY.jl
	julia src/CAY.jl

tmp/predict.csv: src/DataImport.jl input/cay_computed.csv output/msi.csv
	julia src/DataImport.jl

output/predict.csv: src/RiskPremium.jl tmp/predict.csv
	julia src/RiskPremium.jl
```

## Julia Dependencies

- CSV.jl, DataFrames.jl, Dates.jl — data handling
- HTTP.jl or Downloads.jl — FRED API access
- GLM.jl or manual OLS — regression
- CovarianceMatrices.jl or manual implementation — Newey-West HAC
- Plots.jl or CairoMakie.jl — charting
- (Future: FinanceRoutines.jl for CRSP/WRDS integration)

## Validation Strategy

Each module is validated independently against R output before proceeding:

1. **CAY.jl** vs `input/cay_current.csv` — match cay values on Lettau's sample
2. **DataImport.jl dp column** vs R's predict.csv dp column
3. **DataImport.jl rf column** vs R's predict.csv rf column
4. **DataImport.jl rmrf_y3 column** vs R's predict.csv rmrf_y3 column
5. **RiskPremium.jl coefficients** vs R's regression output (dp=3.370, cay=1.814, rf=-1.246)

Tolerance: max absolute difference < 1e-6 for data columns, < 0.01 for regression coefficients (sample differences may cause small deviations).

## Implementation Order

1. CAY.jl — hardest and most novel piece; validate against Lettau
2. DataImport.jl — straightforward port from R; validate against predict.csv
3. RiskPremium.jl — regression and plotting; validate against R output
4. Update Makefile
5. Extend CAY to latest available data and re-run full pipeline
