
R version 4.1.3 (2022-03-10) -- "One Push-Up"
Copyright (C) 2022 The R Foundation for Statistical Computing
Platform: x86_64-apple-darwin17.0 (64-bit)

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
Mon Jun 06 12:38:03 2022
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
> package_to_load <- c("crayon", "devtools", "wesanderson", "ggplot2", "statar", 
+ 	"stringr", "lubridate", "lmtest", "sandwich", "stargazer", "data.table")
> 
> using(package_to_load)
Loading required package: crayon
Loading required package: devtools
Loading required package: usethis
Loading required package: wesanderson
Loading required package: ggplot2

Attaching package: ‘ggplot2’

The following object is masked from ‘package:crayon’:

    %+%

Loading required package: statar
Loading required package: stringr
Loading required package: lubridate

Attaching package: ‘lubridate’

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Loading required package: lmtest
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric


Attaching package: ‘lmtest’

The following object is masked from ‘package:crayon’:

    reset

Loading required package: sandwich
Loading required package: stargazer

Please cite as: 

 Hlavac, Marek (2022). stargazer: Well-Formatted Regression and Summary Statistics Tables.
 R package version 5.2.3. https://CRAN.R-project.org/package=stargazer 

Loading required package: data.table

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

> 
> 
> check_file = file.exists("log/R-session-info.log.R")
> sink("log/R-session-info.log.R", append=check_file)
> cat(bold("\n\n# -----\n# Session info for rp_measure.csv\n\n")) 
> session_info()
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
dp                         3.632***          3.632***          3.370***          3.370***  
                            (0.440)           (1.074)           (0.436)           (1.135)  
                                                                                           
cay                        2.156***          2.156***          1.814***          1.814***  
                            (0.261)           (0.604)           (0.246)           (0.630)  
                                                                                           
rf                         -0.938***         -0.938**          -1.246***         -1.246*** 
                            (0.177)           (0.364)           (0.163)           (0.378)  
                                                                                           
Constant                    -0.019            -0.019             0.011             0.011   
                            (0.015)           (0.037)           (0.013)           (0.036)  
                                                                                           
-------------------------------------------------------------------------------------------
Observations                  236                                 264                      
R2                           0.384                               0.344                     
Adjusted R2                  0.376                               0.336                     
Residual Std. Error    0.074 (df = 232)                    0.074 (df = 260)                
F Statistic         48.181*** (df = 3; 232)             45.459*** (df = 3; 260)            
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
           date         dp         cay     rf    rmrf_y3   exp_rmrf
  1: 1952-03-01 0.05817138  0.01510493 0.0159 0.18092953 0.21495611
  2: 1952-06-01 0.05739649  0.02483727 0.0170 0.21642173 0.22862789
  3: 1952-09-01 0.05709103  0.01484008 0.0171 0.23193277 0.20933933
  4: 1952-12-01 0.05522191  0.02216598 0.0209 0.22202729 0.21159354
  5: 1953-03-01 0.05455042  0.02152118 0.0201 0.26058722 0.20915790
 ---                                                               
260: 2016-12-01 0.02284466 -0.01902802 0.0051 0.11899389 0.04744519
261: 2017-03-01 0.02185142 -0.02168661 0.0074 0.01294375 0.03640904
262: 2017-06-01 0.02147595 -0.02432134 0.0098 0.07365837 0.02737347
263: 2017-09-01 0.02132813 -0.02799587 0.0103 0.08875791 0.01958676
264: 2017-12-01 0.02075782 -0.02490222 0.0132 0.12023222 0.01966250
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
  2.456   0.224   2.887 
