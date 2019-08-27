
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
Tue Aug 27 21:49:26 2019
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
dp                         2.976***          2.976***          2.833***          2.833***  
                            (0.415)           (1.016)           (0.419)           (1.081)  
                                                                                           
cay                        2.561***          2.561***          2.270***          2.270***  
                            (0.242)           (0.548)           (0.233)           (0.565)  
                                                                                           
rf                         -0.861***         -0.861**          -1.152***         -1.152*** 
                            (0.166)           (0.346)           (0.156)           (0.378)  
                                                                                           
Constant                    -0.001            -0.001            0.024*             0.024   
                            (0.014)           (0.034)           (0.013)           (0.036)  
                                                                                           
-------------------------------------------------------------------------------------------
Observations                  236                                 256                      
R2                           0.463                               0.423                     
Adjusted R2                  0.456                               0.416                     
Residual Std. Error    0.069 (df = 232)                    0.070 (df = 252)                
F Statistic         66.603*** (df = 3; 232)             61.652*** (df = 3; 252)            
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
D/P ratio                           2.833***               
                                    (0.419)                
                                                           
cay                                 2.270***               
                                    (0.233)                
                                                           
T-bill (three-month)               -1.152***               
                                    (0.156)                
                                                           
Constant                             0.024*                
                                    (0.013)                
                                                           
Observations                          256                  
R2                                   0.423                 
F Statistic                 61.652*** (df = 3; 252)        
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
> dt_plot <- dt_exp_rmrf[, .(
+ 	date=as.Date(ISOdate(str_sub(dateym,1, 4), as.integer(str_sub(dateym, 5, 6)), 1)), 
+ 	dp, cay, rf, rmrf_y3, exp_rmrf)]
> dt_plot[]
           date         dp         cay     rf    rmrf_y3    exp_rmrf
  1: 1952-03-01 0.05817138  0.01646544 0.0159 0.18092953 0.207727996
  2: 1952-06-01 0.05739649  0.02551783 0.0170 0.21642173 0.224814274
  3: 1952-09-01 0.05709103  0.01633620 0.0171 0.23193277 0.202990900
  4: 1952-12-01 0.05522191  0.02542006 0.0209 0.22202729 0.213936934
  5: 1953-03-01 0.05455042  0.02543387 0.0201 0.26058722 0.212987813
 ---                                                                
252: 2014-12-01 0.02094913 -0.02747550 0.0003 0.09787760 0.020501440
253: 2015-03-01 0.02111608 -0.03462231 0.0003 0.08734601 0.004750878
254: 2015-06-01 0.02111542 -0.03462943 0.0002 0.09928718 0.004848069
255: 2015-09-01 0.02153820 -0.02656083 0.0002 0.15268617 0.024361936
256: 2015-12-01 0.02191271 -0.03519129 0.0023 0.07465740 0.003411385
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
> proc.time()
   user  system elapsed 
  2.563   0.196   2.694 
