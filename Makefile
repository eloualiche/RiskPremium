#
# Makefile for PREDICTING THE EQUITY RISK PREMIUM
#
# Created       on June  04th 2019
# Last modified on April 04th 2019
## --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
## ALL
all: output/predict.csv readme.md

##
## DOWNLOAD THE DATA FROM WRDS
input/msi.sas7bdat: 
	rsync -aPvzh --stats --human-readable  XXXX@wrds-cloud.wharton.upenn.edu:/wrds/crsp/sasdata/a_stock/msi.sas7bdat ./input/

## GENERATE PREDICTORS
tmp/predict.csv: src/import_predictors.R input/cay_current.csv input/msi.sas7bdat
	R CMD BATCH $(R_OPTS) src/import_predictors.R log/import_predictors.log.R

## RUN REGRESSIONS
output/predict.csv: src/rp_measure.R tmp/predict.csv
	R CMD BATCH $(R_OPTS) src/rp_measure.R log/rp_measure.log.R
	@echo

## OUTPUT RESULTS
readme.md: src/readme_in.md 
	cat src/readme_in.md tmp/reg_update.txt > readme.md

##
## --------------------------------------------------------------------------------------------------------
## help (this call)
.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<

## clean
.PHONY : clean
clean:
	rm -rf ./output/*
	rm -rf ./log/*.log*
	rm -rf ./tmp/*	

##
## --------------------------------------------------------------------------------------------------------
SHELL    := /bin/bash
R_OPTS   := --vanilla
# DATE     := `date '+%Y-%m-%d %H:%M:%S'`
# --------------------------------------------------------------------------------------------------------



