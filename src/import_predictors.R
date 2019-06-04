#!/usr/bin/env Rscript  
#
# import_predictors.R
#
# This code creates or imports the predictors of aggregate equity returns
# There are three parts for T-bill, D/P ratio and cay 
# 
# 1. T-bill comes from the H15 release of the FRB 
#    we downloaded it directly from FRED at https://fred.stlouisfed.org/series/TB3MS
#
# 2. cay comes from Martin Lettau's website at http://faculty.haas.berkeley.edu/lettau/data_cay.html
#
# 3. D-P ratio is estimated from the MSI CRSP Files 
#    We use a method of continuously reinvested dividends
#    See attached LaTeX file for explanations of the procedure
#    Data is from CRSP and available at /wrds/crsp/sasdata/a_stock/msi.sas7bdat
#
# 4. Estimate future excess returns: we use a horizon of three years in the paper
#
# (c) Valentin Haddad, Erik Loualiche & Matthew Plosser
#
# Last updated on June 4th 2019
# 
##################################################################################


##################################################################################
message("Log file for code executed at\n")
message(format(Sys.time(), "%a %b %d %X %Y"))
##################################################################################


##################################################################################
# APPEND REQUIRED PACKAGES
library(crayon)
library(devtools)

library(alfred)
library(haven)
library(dplyr)
library(stringr)
library(lubridate)
library(RcppRoll)
library(statar)
library(data.table)

check_file = file.exists("log/R-session-info.log.R")
sink("log/R-session-info.log.R", append=check_file)
cat(bold("\n\n# -----\n# Session info for import_predictors\n\n")) 
session_info()
sink()
##################################################################################


##################################################################################
# 1. TREASURIES
dt_tbill <- get_fred_series("TB3MS", "rf", observation_start = "1950-01-01", observation_end = "2019-05-31") %>% data.table
dt_tbill <- dt_tbill[, .(dateym=year(date)*100+month(date), rf=rf/100)]
# fwrite(dt_tbill, "./input/tbill.csv")
##################################################################################


##################################################################################
# 2. CAY
dt_cay <- fread("./input/cay_current.csv", skip=1, header=T)
dt_cay <- dt_cay[, .(dateym=as.integer(str_sub(date, 1, 6)), cay=cay) ]
dt_cay
##################################################################################


##################################################################################
# 3. Dividend-Price RATIO
dt_msi <- read_sas("./input/msi.sas7bdat") %>% data.table
dt_msi <- dt_msi[, .(date=DATE, vwretd, vwretx) ]
fwrite(dt_msi, "./output/msi.csv") # SAVED HERE IF YOU NEED IT

# ESTIMATE THE DP RATIO
dt_dp <- dt_msi[, .(date, vwretx, vwretd, vwrx=1+vwretx, vwrd=1+vwretd) ]
dt_dp[, `:=`(vwrx=1+vwretx, vwrd=1+vwretd) ]
dt_dp[, `:=`(dpvw = 100 * (vwretd-vwretx) / (1+vwretx) ) ]
dt_dp[, `:=`(retd_retx = (1+vwretd) / (1+vwretx) ) ]
dt_dp[, `:=`(datem = as.monthly(date)) ]
dt_dp[, dp := 0 ]
for (i in seq(11,0)){
	dt_dp[, dp := (dp*tlag(retd_retx, i, time=datem) + tlag(dpvw, i, time=datem)) ]
}
dt_dp <- dt_dp[, .(dateym=year(datem)*100+month(datem), dp=dp/100)]
dt_dp[]
##################################################################################


##################################################################################
# ESTIMATE FUTURE EXCESS RETURNS
dt_rmrf   <- fread("./output/msi.csv") %>% data.table
dt_rmrf   <- dt_rmrf[, .(dateym=year(date)*100+month(date), retm=vwretd) ]
dt_rmrf   <- merge(dt_rmrf, dt_tbill, by = "dateym")

dt_rmrf[, lead1_retm := shift(retm, 1, type="lead") ]
dt_rmrf[, retm_y := exp( roll_sum(log(1+lead1_retm), n=12, align="left", fill=NA) ) - 1 ]
dt_rmrf[, rf_y := (1+rf)^(1/4) * (1+shift(rf, 3, type="lead"))^(1/4) * 
                 (1+shift(rf, 6, type="lead"))^(1/4) * (1+shift(rf, 9, type="lead"))^(1/4) - 1 ]
dt_rmrf[, rmrf_y3 := 1 * ( 
	( (1+retm_y) * (1 + shift(retm_y, 12, type="lead")) * (1 + shift(retm_y, 24, type="lead")) )^(1/3) - 
	( ((1+rf_y)  * (1 + shift(rf_y,   12, type="lead")) * (1 + shift(rf_y, 24, type="lead")) )^(1/3) - 1) -1) ]

dt_rmrf <- dt_rmrf[, .(dateym, rmrf_y3) ]
dt_rmrf[ !is.na(rmrf_y3) ]
##################################################################################


##################################################################################
# MERGE THE PREDICTORS
dt_predict <- merge(dt_dp, dt_tbill, by = c("dateym"))
dt_predict <- merge(dt_predict, dt_rmrf, by = c("dateym"), all.x = T)
dt_predict <- merge(dt_predict, dt_cay, by = c("dateym"), all.x = T)
dt_predict <- dt_predict[ !is.na(rmrf_y3) & !is.na(cay) ]
dt_predict[]

fwrite(dt_predict, "./tmp/predict.csv")
##################################################################################














