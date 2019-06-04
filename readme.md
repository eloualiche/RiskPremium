# Measuring the Risk Premium

1. Measuring Dividend Price ratio uses CRSP Monthly Index files available on [WRDS](https://wrds-web.wharton.upenn.edu/wrds/ds/crsp/stock_a/stkmktix.cfm)
   - `msi.sas7bdat` downloaded from `/wrds/crsp/sasdata/a_stock/msi.sas7bdat`
   - See our [note](./doc/dividendpriceratio.pdf) on how to account for reinvested dividends
2. Measuring the risk-free rate from H15 release available on [FRED](https://fred.stlouisfed.org/series/TB3MS
)
3. Measuring cay from Lettau's [website](http://faculty.haas.berkeley.edu/lettau/data_cay.html). *Last downloaded on May 29 2019*


## Latest estimates 


~~~R
===========================================================
                             Future Excess Returns         
-----------------------------------------------------------
D/P ratio                           2.788***               
                                    (0.411)                
                                                           
cay                                 2.076***               
                                    (0.234)                
                                                           
T-bill (three-month)               -1.093***               
                                    (0.151)                
                                                           
Constant                             0.022*                
                                    (0.013)                
                                                           
Observations                          256                  
R2                                   0.400                 
F Statistic                 56.022*** (df = 3; 252)        
-----------------------------------------------------------
Notes:               ***Significant at the 1 percent level.
                     **Significant at the 5 percent level. 
                     *Significant at the 10 percent level. 
~~~
