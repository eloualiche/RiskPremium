#!/usr/bin/env Rscript  
#
# rp_measure.R
#
# This code runs the predictive regression
# We save in output the expected excess return estimate
# 
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

# library(ggplot2)
library(statar)
library(stringr)
library(lubridate)
library(data.table)
library(lmtest)
library(sandwich)
library(stargazer)

check_file = file.exists("log/R-session-info.log.R")
sink("log/R-session-info.log.R", append=check_file)
cat(bold("\n\n# -----\n# Session info for rp_measure.csv\n\n")) 
session_info()
sink()
##################################################################################


##################################################################################
dt_predict <- fread("./tmp/predict.csv")
dt_predict[, datem := as.monthly(ISOdate(str_sub(dateym, 1, 4), str_sub(dateym, 5, 6), 1)) ]
##################################################################################


##################################################################################
r1_3 = lm(rmrf_y3 ~ dp + cay + rf, data = dt_predict[ year(datem) < 2011])
nw_r1_3 = coeftest(r1_3, df = Inf, vcov = NeweyWest(r1_3, lag = 12, prewhite = FALSE) )
r2_3 = lm(rmrf_y3 ~ dp + cay + rf, data = dt_predict)
nw_r2_3 = coeftest(r2_3, df = Inf, vcov = NeweyWest(r2_3, lag = 12, prewhite = FALSE) )

stargazer(r1_3, nw_r1_3, r2_3, nw_r2_3, type="text")

# --- output for the readme
star = stargazer(r2_3, type="text",  style = "aer",
	covariate.labels = c("D/P ratio", "cay", "T-bill (three-month)"),
	dep.var.labels   = "Future Excess Returns",
	omit.stat = c("ser", "adj.rsq") )

star[1] = "~~~R"
star[length(star)+1] = "~~~"
cat(star, sep = '\n', file = './tmp/reg_update.txt')
##################################################################################


##################################################################################
# OUTPUT PREDICTED VALUE
dt_exp_rmrf <- cbind(dt_predict[!is.na(rmrf_y3), -c("datem")], exp_rmrf = predict(r2_3))

fwrite(dt_exp_rmrf, "./output/predict.csv")
##################################################################################

