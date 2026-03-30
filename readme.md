# Measuring the Market Risk Premium

![](output/predict.pdf)


This code updates the measure of equity risk premium.

We use the dividend-price ratio, cay and the three-month T-bill to predict future excess returns

+ *Haddad Valentin, Erik Loualiche, and Matthew Plosser*: **Buyout Activity: the Impact of Aggregate Discount Rates**;  Journal of Finance, February 2017, 72:1
+ [Download the paper](http://loualiche.gitlab.io/www/abstract/LBO.html)
+ [Download the data](https://github.com/eloualiche/RiskPremium/releases)


## Releases

**For the exact replication of the published paper, use [v1.0](https://github.com/eloualiche/RiskPremium/releases/tag/v1.0).** That release uses the original R pipeline with Lettau's cay downloaded directly from his [website](http://faculty.haas.berkeley.edu/lettau/data_cay.html) (1952Q1–2019Q3). CRSP data through 2017Q4. Regression coefficients: D/P = 3.370, cay = 1.814, T-bill = −1.246, R² = 0.344 (264 obs).

**For updated estimates, use [v2.0](https://github.com/eloualiche/RiskPremium/releases/tag/v2.0).** This release rewrites the pipeline in Julia and constructs cay from publicly available FRED data, removing the dependency on Lettau's website. CRSP data through 2024Q4. DOLS coefficients: β_a = 0.195, β_y = 0.863 (estimation sample: 1951Q4–2019Q3). Regression coefficients: D/P = 2.779, cay = 0.398, T-bill = −1.232, R² = 0.234 (285 obs). See the [construction of cay](#construction-of-cay) section below for validation details.


## Data Sources

1. **Dividend-price ratio** from CRSP Monthly Stock Market Index (`crsp.msi`), available on [WRDS](https://wrds-web.wharton.upenn.edu/wrds/ds/crsp/stock_a/stkmktix.cfm)
   - See the calculations to account for reinvested dividends in this [note](./docs/dividendpriceratio.pdf)
2. **Risk-free rate** from the H15 release: 3-month T-bill ([`TB3MS`](https://fred.stlouisfed.org/series/TB3MS)) downloaded from [FRED](https://fred.stlouisfed.org)
3. **cay** (consumption-wealth ratio) constructed from FRED data following [Lettau and Ludvigson (2001)](https://doi.org/10.1111/0022-1082.00347). See details below.


## Construction of cay

**In v1.0**, cay was downloaded directly from Martin Lettau's [website](http://faculty.haas.berkeley.edu/lettau/data_cay.html), last updated 2019Q3. That series is no longer maintained.

**In v2.0**, we construct cay from publicly available FRED data. The cointegrating vector is estimated on the same sample period as Lettau (1951Q4–2019Q3), and cay is then computed out of sample through the latest available quarter.

### Definition

cay is the residual from a cointegrating regression of log real per-capita consumption on log real per-capita asset wealth and log real per-capita labor income:

```
c_t = α + β_a · a_t + β_y · y_t + cay_t
```

The cointegrating vector is estimated by Stock-Watson Dynamic OLS (DOLS) with 8 leads and lags of the first-differenced regressors.

### Data sources (all from FRED)

| Variable | FRED series | Description |
|---|---|---|
| Consumption (c) | [`PCEC`](https://fred.stlouisfed.org/series/PCEC) | Personal Consumption Expenditures, quarterly, SAAR |
| Asset wealth (a) | [`TNWBSHNO`](https://fred.stlouisfed.org/series/TNWBSHNO) | Households and Nonprofits Net Worth (Z.1) |
| Wages and salaries | [`WASCUR`](https://fred.stlouisfed.org/series/WASCUR) | Compensation of Employees: Wages and Salary Accruals |
| Transfer payments | [`A577RC1Q027SBEA`](https://fred.stlouisfed.org/series/A577RC1Q027SBEA) | Personal Current Transfer Receipts |
| Other labor income | [`B040RC1Q027SBEA`](https://fred.stlouisfed.org/series/B040RC1Q027SBEA) | Employer Contributions for Employee Pension and Insurance |
| Social insurance | [`A061RC1Q027SBEA`](https://fred.stlouisfed.org/series/A061RC1Q027SBEA) | Contributions for Government Social Insurance |
| Personal income | [`PINCOME`](https://fred.stlouisfed.org/series/PINCOME) | Personal Income |
| Personal taxes | [`W055RC1Q027SBEA`](https://fred.stlouisfed.org/series/W055RC1Q027SBEA) | Personal Current Taxes |
| Price deflator | [`PCECTPI`](https://fred.stlouisfed.org/series/PCECTPI) | PCE Chain-Type Price Index (2017=100) |
| Population | [`B230RC0Q173SBEA`](https://fred.stlouisfed.org/series/B230RC0Q173SBEA) | BEA Midperiod Population |

Labor income follows Lettau and Ludvigson (2001, Appendix): wages + transfers + other labor income − social insurance contributions − (labor share × personal taxes), where labor share = pre-tax labor income / personal income.

All nominal series are deflated by PCECTPI and divided by population to obtain real per-capita values.

### Validation against Lettau's published series

We compare our constructed cay to Lettau's published series (1952Q1–2019Q3, 271 quarterly observations) on the same estimation sample. Current FRED vintages differ from Lettau's due to the 2023 NIPA comprehensive revision, which rescaled the PCE deflator by approximately 6%.

**Component-level accuracy:**

| | Correlation of levels | Max first-difference error |
|---|---|---|
| Consumption (c) | 0.99998 | 0.0046 |
| Asset wealth (a) | 0.99993 | 0.0083 |
| Labor income (y) | 0.99988 | 0.0075 |

**DOLS coefficients** (estimation sample: 1951Q4–2019Q3):

| | Lettau | Ours |
|---|---|---|
| β_a (wealth) | 0.218 | 0.195 |
| β_y (income) | 0.801 | 0.863 |

**cay series correlation** (demeaned): 0.986

**Impact on predicted risk premium** (264 common observations, 1952Q1–2017Q4):

| | Lettau cay (v1.0) | Our cay (v2.0) |
|---|---|---|
| D/P coefficient | 3.370 | 3.385 |
| cay coefficient | 1.814 | 1.564 |
| T-bill coefficient | −1.246 | −1.336 |
| R² | 0.344 | 0.332 |

The predicted risk premium from both specifications has correlation 0.997. The mean absolute difference is 0.35 percentage points; 77% of observations differ by less than 0.5pp and 98% by less than 1pp.


## Latest estimates


~~~R
===========================================================
                             Future Excess Returns         
-----------------------------------------------------------
D/P ratio                                      2.779***
                                                (1.021)

cay                                               0.398
                                                 (0.36)

T-bill (three-month)                          -1.232***
                                                (0.306)

Constant                                          0.034
                                                (0.035)

Observations                                        285
R2                                                0.234
-----------------------------------------------------------
Notes:               ***Significant at the 1 percent level.
                     **Significant at the 5 percent level. 
                     *Significant at the 10 percent level. 
~~~