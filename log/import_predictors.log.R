
R version 3.6.2 (2019-12-12) -- "Dark and Stormy Night"
Copyright (C) 2019 The R Foundation for Statistical Computing
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
Mon Mar 23 08:59:59 2020
> ##################################################################################
> 
> 
> ##################################################################################
> # APPEND REQUIRED PACKAGES
> 
> # See this https://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
> using<-function(...) {
+     libs<-unlist(list(...))
+     req<-unlist(lapply(libs,require,character.only=TRUE))
+     need<-libs[req==FALSE]
+     if(length(need)>0){ 
+         install.packages(need)
+         lapply(need,require,character.only=TRUE)
+     }
+ }
> 
> package_to_load <- c("crayon", "devtools", "alfred", "haven", "dplyr", 
+ 	"stringr", "lubridate", "RcppRoll", "statar", "data.table")
> using(package_to_load)
Loading required package: crayon
Loading required package: devtools
Loading required package: usethis
Loading required package: alfred
Loading required package: haven
Loading required package: dplyr

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Loading required package: stringr
Loading required package: lubridate

Attaching package: ‘lubridate’

The following object is masked from ‘package:base’:

    date

Loading required package: RcppRoll
Loading required package: statar
Loading required package: data.table

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
> sink()
> ##################################################################################
> 
> 
> ##################################################################################
> # 1. TREASURIES
> dt_tbill <- get_fred_series("TB3MS", "rf", observation_start = "1950-01-01", observation_end = "2020-12-31") %>% data.table
> dt_tbill <- dt_tbill[, .(dateym=year(date)*100+month(date), rf=rf/100)]
> dt_tbill[]
     dateym     rf
  1: 195001 0.0107
  2: 195002 0.0112
  3: 195003 0.0112
  4: 195004 0.0115
  5: 195005 0.0116
 ---              
838: 201910 0.0165
839: 201911 0.0154
840: 201912 0.0154
841: 202001 0.0152
842: 202002 0.0152
> # fwrite(dt_tbill, "./input/tbill.csv")
> ##################################################################################
> 
> 
> ##################################################################################
> # 2. CAY
> dt_cay <- fread("./input/cay_current.csv", skip=0, header=T)
> setnames(dt_cay, c("date", "c", "w", "y", "cay"))
> dt_cay <- dt_cay[, .(date_y=year(date), month = month(date), cay) ]
> dt_cay <- dt_cay[, .(dateym=date_y*100+month, cay) ]
> dt_cay[]
     dateym         cay
  1: 195203  0.01510493
  2: 195206  0.02483727
  3: 195209  0.01484008
  4: 195212  0.02216598
  5: 195303  0.02152118
 ---                   
267: 201809 -0.02934508
268: 201812 -0.02020734
269: 201903 -0.04435449
270: 201906 -0.03764155
271: 201909 -0.03665922
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
1125: 201908 0.02129861
1126: 201909 0.02150184
1127: 201910 0.02149657
1128: 201911 0.02113526
1129: 201912 0.02085788
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
     dateym   rmrf_y3
  1: 195001 0.1916460
  2: 195002 0.1844133
  3: 195003 0.1738962
  4: 195004 0.1472840
  5: 195005 0.1328846
 ---                 
800: 201608 0.0992516
801: 201609 0.1035328
802: 201610 0.1184933
803: 201611 0.1160087
804: 201612 0.1191020
> ##################################################################################
> 
> 
> ##################################################################################
> # MERGE THE PREDICTORS
> dt_predict <- merge(dt_dp, dt_tbill, by = c("dateym"))
> dt_predict <- merge(dt_predict, dt_rmrf, by = c("dateym"), all.x = T)
> dt_predict <- merge(dt_predict, dt_cay, by = c("dateym"), all.x = T)
> dt_predict <- dt_predict[ !is.na(rmrf_y3) ]
> dt_predict <- dt_predict[ !is.na(cay) ]
> dt_predict[]
     dateym         dp     rf    rmrf_y3         cay
  1: 195203 0.05817138 0.0159 0.18092953  0.01510493
  2: 195206 0.05739649 0.0170 0.21642173  0.02483727
  3: 195209 0.05709103 0.0171 0.23193277  0.01484008
  4: 195212 0.05522191 0.0209 0.22202729  0.02216598
  5: 195303 0.05455042 0.0201 0.26058722  0.02152118
 ---                                                
256: 201512 0.02191273 0.0023 0.07466284 -0.02350179
257: 201603 0.02265601 0.0029 0.11699368 -0.02321807
258: 201606 0.02307582 0.0027 0.11884748 -0.01823511
259: 201609 0.02297658 0.0029 0.10353283 -0.01942223
260: 201612 0.02284611 0.0051 0.11910203 -0.01902802
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
  2.462   0.335   4.291 
