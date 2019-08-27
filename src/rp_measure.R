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
library(wesanderson)
library(ggplot2)
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


##################################################################################
# PLOT
dt_plot <- dt_exp_rmrf[, .(
	date=as.Date(ISOdate(str_sub(dateym,1, 4), as.integer(str_sub(dateym, 5, 6)), 1)), 
	dp, cay, rf, rmrf_y3, exp_rmrf)]
dt_plot[]


p0 <- dt_plot[, .(date, dp, cay, rf, rmrf_y3) ] %>% 
    melt(id.vars="date") %>%
	ggplot(aes(date, value, colour = variable)) + 
	geom_line(alpha=0.75, size=0.25) + geom_point(shape=1, size = 1, alpha=0.5) + 
	theme_bw()
# p0

p1 <- dt_plot[, .(date, exp_rmrf, rmrf_y3) ] %>% 
 	melt(id.vars="date") %>%
	ggplot(aes(date, 100*value, colour = variable)) + 
	geom_line(alpha=0.75, size=0.25) + geom_point(shape=1, size = 1, alpha=0.5) + 
	xlab("") + ylab("Returns (percent)") + 
	theme_bw() +
	theme(legend.position = c(0.3, 0.9)) + 
	scale_colour_manual(name  = "",
                        breaks = c("exp_rmrf", "rmrf_y3"),
                        values = c(wes_palette("Zissou1")[1], wes_palette("Zissou1")[5]),
                        labels=c("Expected", "Realized")) + 
	guides(colour = guide_legend(nrow = 1))
ggsave("./output/predict.png", p1, width = 8, height=6)
##################################################################################


##################################################################################