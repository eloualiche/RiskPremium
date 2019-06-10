
R version 3.5.1 (2018-07-02) -- "Feather Spray"
Copyright (C) 2018 The R Foundation for Statistical Computing
Platform: x86_64-apple-darwin15.6.0 (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> #!/usr/bin/env Rscript  
> #
> # import_predictors.R
> #
> # This code creates or imports the predictors of aggregate equity returns
> # There are three parts for T-bill, D/P ratio and cay 
> # 
> # 1. T-bill comes from the H15 release of the FRB 
> #    we downloaded it directly from FRED at https://fred.stlouisfed.org/series/TB3MS
> #
> # 2. cay comes from Martin Lettau's website at http://faculty.haas.berkeley.edu/lettau/data_cay.html
> #
> # 3. D-P ratio is estimated from the MSI CRSP Files 
> #    We use a method of continuously reinvested dividends
> #    See attached LaTeX file for explanations of the procedure
> #    Data is from CRSP and available at /wrds/crsp/sasdata/a_stock/msi.sas7bdat
> #
> # 4. Estimate future excess returns: we use a horizon of three years in the paper
> #
> # (c) Valentin Haddad, Erik Loualiche & Matthew Plosser
> #
> # Last updated on June 4th 2019
> # 
> ##################################################################################
> 
> 
> ##################################################################################
> message("Log file for code executed at\n")
Log file for code executed at

> message(format(Sys.time(), "%a %b %d %X %Y"))
Mon Jun 10 11:42:28 2019
> ##################################################################################
> 
> 
> ##################################################################################
> # APPEND REQUIRED PACKAGES
> library(crayon)
> library(devtools)
> 
> library(alfred)
> library(haven)
> library(dplyr)

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

> library(stringr)
> library(lubridate)

Attaching package: ‘lubridate’

The following object is masked from ‘package:base’:

    date

> library(RcppRoll)
> library(statar)
> library(data.table)

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

> 
> check_file = file.exists("log/R-session-info.log.R")
> sink("log/R-session-info.log.R", append=check_file)
> cat(bold("\n\n# -----\n# Session info for import_predictors\n\n")) 
> session_info()
Session info ------------------------------------------------------------------
Packages ----------------------------------------------------------------------
> sink()
> ##################################################################################
> 
> 
> ##################################################################################
> # 1. TREASURIES
> dt_tbill <- get_fred_series("TB3MS", "rf", observation_start = "1950-01-01", observation_end = "2019-05-31") %>% data.table
> dt_tbill <- dt_tbill[, .(dateym=year(date)*100+month(date), rf=rf/100)]
> # fwrite(dt_tbill, "./input/tbill.csv")
> ##################################################################################
> 
> 
> ##################################################################################
> # 2. CAY
> dt_cay <- fread("./input/cay_current.csv", skip=1, header=T)
> dt_cay <- dt_cay[, .(dateym=as.integer(str_sub(date, 1, 6)), cay=cay) ]
> dt_cay
     dateym         cay
  1: 195201  0.01646544
  2: 195202  0.02551783
  3: 195203  0.01633620
  4: 195204  0.02542006
  5: 195301  0.02543387
 ---                   
259: 201603 -0.02916950
260: 201604 -0.02042846
261: 201701 -0.02529660
262: 201702 -0.02655350
263: 201703 -0.02760623
> ##################################################################################
> 
> 
> ##################################################################################
> # 3. Dividend-Price RATIO
> dt_msi <- read_sas("./input/msi.sas7bdat") %>% data.table
> dt_msi <- dt_msi[, .(date=DATE, vwretd, vwretx) ]
> fwrite(dt_msi, "./output/msi.csv") # SAVED HERE IF YOU NEED IT
> 
> # ESTIMATE THE DP RATIO
> dt_dp <- dt_msi[, .(date, vwretx, vwretd, vwrx=1+vwretx, vwrd=1+vwretd) ]
> dt_dp[, `:=`(vwrx=1+vwretx, vwrd=1+vwretd) ]
> dt_dp[, `:=`(dpvw = 100 * (vwretd-vwretx) / (1+vwretx) ) ]
> dt_dp[, `:=`(retd_retx = (1+vwretd) / (1+vwretx) ) ]
> dt_dp[, `:=`(datem = as.monthly(date)) ]
> dt_dp[, dp := 0 ]
> for (i in seq(11,0)){
+ 	dt_dp[, dp := (dp*tlag(retd_retx, i, time=datem) + tlag(dpvw, i, time=datem)) ]
+ }
> dt_dp <- dt_dp[, .(dateym=year(datem)*100+month(datem), dp=dp/100)]
> dt_dp[]
      dateym         dp
   1: 192512         NA
   2: 192601         NA
   3: 192602         NA
   4: 192603         NA
   5: 192604         NA
  ---                  
1113: 201808 0.02033382
1114: 201809 0.02040150
1115: 201810 0.02047582
1116: 201811 0.02050859
1117: 201812 0.02114445
> ##################################################################################
> 
> 
> ##################################################################################
> # ESTIMATE FUTURE EXCESS RETURNS
> dt_rmrf   <- fread("./output/msi.csv") %>% data.table
> dt_rmrf   <- dt_rmrf[, .(dateym=year(date)*100+month(date), retm=vwretd) ]
> dt_rmrf   <- merge(dt_rmrf, dt_tbill, by = "dateym")
> 
> dt_rmrf[, lead1_retm := shift(retm, 1, type="lead") ]
> dt_rmrf[, retm_y := exp( roll_sum(log(1+lead1_retm), n=12, align="left", fill=NA) ) - 1 ]
> dt_rmrf[, rf_y := (1+rf)^(1/4) * (1+shift(rf, 3, type="lead"))^(1/4) * 
+                  (1+shift(rf, 6, type="lead"))^(1/4) * (1+shift(rf, 9, type="lead"))^(1/4) - 1 ]
> dt_rmrf[, rmrf_y3 := 1 * ( 
+ 	( (1+retm_y) * (1 + shift(retm_y, 12, type="lead")) * (1 + shift(retm_y, 24, type="lead")) )^(1/3) - 
+ 	( ((1+rf_y)  * (1 + shift(rf_y,   12, type="lead")) * (1 + shift(rf_y, 24, type="lead")) )^(1/3) - 1) -1) ]
> 
> dt_rmrf <- dt_rmrf[, .(dateym, rmrf_y3) ]
> dt_rmrf[ !is.na(rmrf_y3) ]
     dateym    rmrf_y3
  1: 195001 0.19164596
  2: 195002 0.18441326
  3: 195003 0.17389623
  4: 195004 0.14728401
  5: 195005 0.13288460
 ---                  
788: 201508 0.13987039
789: 201509 0.15268617
790: 201510 0.09634409
791: 201511 0.10151984
792: 201512 0.07465740
> ##################################################################################
> 
> 
> ##################################################################################
> # MERGE THE PREDICTORS
> dt_predict <- merge(dt_dp, dt_tbill, by = c("dateym"))
> dt_predict <- merge(dt_predict, dt_rmrf, by = c("dateym"), all.x = T)
> dt_predict <- merge(dt_predict, dt_cay, by = c("dateym"), all.x = T)
> dt_predict <- dt_predict[ !is.na(rmrf_y3) & !is.na(cay) ]
> dt_predict[]
     dateym         dp     rf    rmrf_y3         cay
  1: 195201 0.05812871 0.0157 0.17701996  0.01646544
  2: 195202 0.05899675 0.0154 0.19964326  0.02551783
  3: 195203 0.05817138 0.0159 0.18092953  0.01633620
  4: 195204 0.05847809 0.0157 0.21473395  0.02542006
  5: 195301 0.05472504 0.0196 0.21110181  0.02543387
 ---                                                
252: 201404 0.02159773 0.0003 0.08441447 -0.02747550
253: 201501 0.02090927 0.0003 0.12632351 -0.03462231
254: 201502 0.02098770 0.0002 0.09072934 -0.03462943
255: 201503 0.02111608 0.0003 0.08734601 -0.02656083
256: 201504 0.02109137 0.0002 0.08565438 -0.03519129
> 
> fwrite(dt_predict, "./tmp/predict.csv")
> ##################################################################################
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> 
> proc.time()
   user  system elapsed 
  1.670   0.187   2.484 
