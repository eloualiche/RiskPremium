
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
> # rp_measure.R
> #
> # This code runs the predictive regression
> # We save in output the expected excess return estimate
> # 
> #
> # (c) Valentin Haddad, Erik Loualiche & Matthew Plosser
> #
> # Last updated on June 4th 2019
> # 
> ##################################################################################
> 
> ##################################################################################
> message("Log file for code executed at\n")
Log file for code executed at

> message(format(Sys.time(), "%a %b %d %X %Y"))
Tue Jun 04 14:33:17 2019
> ##################################################################################
> 
> 
> ##################################################################################
> # APPEND REQUIRED PACKAGES
> library(crayon)
> library(devtools)
> library(wesanderson)
> library(ggplot2)

Attaching package: ‘ggplot2’

The following object is masked from ‘package:crayon’:

    %+%

> library(statar)
> library(stringr)
> library(lubridate)

Attaching package: ‘lubridate’

The following object is masked from ‘package:base’:

    date

> library(data.table)

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

> library(lmtest)
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric


Attaching package: ‘lmtest’

The following object is masked from ‘package:crayon’:

    reset

> library(sandwich)
> library(stargazer)

Please cite as: 

 Hlavac, Marek (2018). stargazer: Well-Formatted Regression and Summary Statistics Tables.
 R package version 5.2.2. https://CRAN.R-project.org/package=stargazer 

> 
> check_file = file.exists("log/R-session-info.log.R")
> sink("log/R-session-info.log.R", append=check_file)
> cat(bold("\n\n# -----\n# Session info for rp_measure.csv\n\n")) 
> session_info()
Session info ------------------------------------------------------------------
Packages ----------------------------------------------------------------------
> sink()
> ##################################################################################
> 
> 
> ##################################################################################
> dt_predict <- fread("./tmp/predict.csv")
> dt_predict[, datem := as.monthly(ISOdate(str_sub(dateym, 1, 4), str_sub(dateym, 5, 6), 1)) ]
> ##################################################################################
> 
> 
> ##################################################################################
> r1_3 = lm(rmrf_y3 ~ dp + cay + rf, data = dt_predict[ year(datem) < 2011])
> nw_r1_3 = coeftest(r1_3, df = Inf, vcov = NeweyWest(r1_3, lag = 12, prewhite = FALSE) )
> r2_3 = lm(rmrf_y3 ~ dp + cay + rf, data = dt_predict)
> nw_r2_3 = coeftest(r2_3, df = Inf, vcov = NeweyWest(r2_3, lag = 12, prewhite = FALSE) )
> 
> stargazer(r1_3, nw_r1_3, r2_3, nw_r2_3, type="text")

===========================================================================================
                                              Dependent variable:                          
                    -----------------------------------------------------------------------
                            rmrf_y3                             rmrf_y3                    
                              OLS           coefficient           OLS           coefficient
                                               test                                test    
                              (1)               (2)               (3)               (4)    
-------------------------------------------------------------------------------------------
dp                         2.932***          2.932***          2.788***          2.788***  
                            (0.411)           (1.022)           (0.411)           (1.077)  
                                                                                           
cay                        2.363***          2.363***          2.076***          2.076***  
                            (0.244)           (0.545)           (0.234)           (0.568)  
                                                                                           
rf                         -0.852***         -0.852**          -1.093***         -1.093*** 
                            (0.161)           (0.353)           (0.151)           (0.376)  
                                                                                           
Constant                     0.001             0.001            0.022*             0.022   
                            (0.014)           (0.036)           (0.013)           (0.036)  
                                                                                           
-------------------------------------------------------------------------------------------
Observations                  236                                 256                      
R2                           0.438                               0.400                     
Adjusted R2                  0.431                               0.393                     
Residual Std. Error    0.070 (df = 232)                    0.070 (df = 252)                
F Statistic         60.270*** (df = 3; 232)             56.022*** (df = 3; 252)            
===========================================================================================
Note:                                                           *p<0.1; **p<0.05; ***p<0.01
> 
> # --- output for the readme
> star = stargazer(r2_3, type="text",  style = "aer",
+ 	covariate.labels = c("D/P ratio", "cay", "T-bill (three-month)"),
+ 	dep.var.labels   = "Future Excess Returns",
+ 	omit.stat = c("ser", "adj.rsq") )

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
> 
> star[1] = "~~~R"
> star[length(star)+1] = "~~~"
> cat(star, sep = '\n', file = './tmp/reg_update.txt')
> ##################################################################################
> 
> 
> ##################################################################################
> # OUTPUT PREDICTED VALUE
> dt_exp_rmrf <- cbind(dt_predict[!is.na(rmrf_y3), -c("datem")], exp_rmrf = predict(r2_3))
> 
> fwrite(dt_exp_rmrf, "./output/predict.csv")
> ##################################################################################
> 
> 
> ##################################################################################
> # PLOT
> dt_plot <- dt_exp_rmrf[, .(date=as.Date(ISOdate(str_sub(dateym,1, 4), str_sub(dateym, 5, 6), 1)), 
+ 	dp, cay, rf, rmrf_y3, exp_rmrf)]
> dt_plot[]
           date         dp         cay     rf    rmrf_y3    exp_rmrf
  1: 1952-01-01 0.05812871  0.01646544 0.0157 0.17701996 0.201294617
  2: 1952-02-01 0.05899675  0.02551783 0.0154 0.19964326 0.222836429
  3: 1952-03-01 0.05817138  0.01633620 0.0159 0.18092953 0.200926735
  4: 1952-04-01 0.05847809  0.02542006 0.0157 0.21473395 0.220859636
  5: 1953-01-01 0.05472504  0.02543387 0.0196 0.21110181 0.206163415
 ---                                                                
252: 2014-04-01 0.02159773 -0.02747550 0.0003 0.08441447 0.025044998
253: 2015-01-01 0.02090927 -0.03462231 0.0003 0.12632351 0.008287874
254: 2015-02-01 0.02098770 -0.03462943 0.0002 0.09072934 0.008601014
255: 2015-03-01 0.02111608 -0.02656083 0.0003 0.08734601 0.025601134
256: 2015-04-01 0.02109137 -0.03519129 0.0002 0.08565438 0.007723565
> 
> 
> p0 <- dt_plot[, .(date, dp, cay, rf, rmrf_y3) ] %>% 
+     melt(id.vars="date") %>%
+ 	ggplot(aes(date, value, colour = variable)) + 
+ 	geom_line(alpha=0.75, size=0.25) + geom_point(shape=1, size = 1, alpha=0.5) + 
+ 	theme_bw()
> # p0
> 
> p1 <- dt_plot[, .(date, exp_rmrf, rmrf_y3) ] %>% 
+  	melt(id.vars="date") %>%
+ 	ggplot(aes(date, 100*value, colour = variable)) + 
+ 	geom_line(alpha=0.75, size=0.25) + geom_point(shape=1, size = 1, alpha=0.5) + 
+ 	xlab("") + ylab("Returns (percent)") + 
+ 	theme_bw() +
+ 	theme(legend.position = c(0.3, 0.9)) + 
+ 	scale_colour_manual(name  = "",
+                         breaks = c("exp_rmrf", "rmrf_y3"),
+                         values = c(wes_palette("Zissou1")[1], wes_palette("Zissou1")[5]),
+                         labels=c("Expected", "Realized")) + 
+ 	guides(colour = guide_legend(nrow = 1))
> ggsave("./output/predict.png", p1, width = 8, height=6)
> ##################################################################################
> 
> 
> ##################################################################################
> 
> 
> 
> proc.time()
   user  system elapsed 
  2.539   0.266   2.953 
