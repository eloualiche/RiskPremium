# Measuring the Market Risk Premium

![](output/predict.png)


This code updates the measure of equity risk premium.

We use the dividend-price ratio, cay and the three-month T-bill to predict future excess returns

+ *Haddad Valentin, Erik Loualiche, and Matthew Plosser*: **Buyout Activity: the Impact of Aggregate Discount Rates**;  Journal of Finance, February 2017, 72:1
+ [Download the paper](http://loualiche.gitlab.io/www/abstract/LBO.html)
+ [Download the data](https://github.com/eloualiche/RiskPremium/releases)


## Data Sources

1. Measuring Dividend Price ratio uses CRSP Monthly Index files available on [WRDS](https://wrds-web.wharton.upenn.edu/wrds/ds/crsp/stock_a/stkmktix.cfm)
   - `msi.sas7bdat` downloaded from `/wrds/crsp/sasdata/a_stock/msi.sas7bdat`
   - See the calculations to account for reinvested dividends in this [note](./docs/dividendpriceratio.pdf) on how 
2. Measuring the risk-free rate from H15 release available on [FRED](https://fred.stlouisfed.org/series/TB3MS
)
3. Measuring cay from Lettau's [website](http://faculty.haas.berkeley.edu/lettau/data_cay.html). *Last downloaded on March 23rd 2020*



## Latest estimates 


~~~R
===========================================================
                             Future Excess Returns         
-----------------------------------------------------------
D/P ratio                           3.370***               
                                    (0.436)                
                                                           
cay                                 1.814***               
                                    (0.246)                
                                                           
T-bill (three-month)               -1.246***               
                                    (0.163)                
                                                           
Constant                             0.011                 
                                    (0.013)                
                                                           
Observations                          264                  
R2                                   0.344                 
F Statistic                 45.459*** (df = 3; 260)        
-----------------------------------------------------------
Notes:               ***Significant at the 1 percent level.
                     **Significant at the 5 percent level. 
                     *Significant at the 10 percent level. 
~~~
